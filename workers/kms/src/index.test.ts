import { describe, expect, test } from "bun:test";
import { handleRequest, type Env } from "./index";

const AUTH_TOKEN = "test-auth-token-that-is-long-and-random";
const KEY_V1 = btoa(String.fromCharCode(...new Uint8Array(32).fill(17)));
const KEY_V2 = btoa(String.fromCharCode(...new Uint8Array(32).fill(42)));

function environment(overrides: Env = {}): Env {
  return {
    CURRENT_KEY_VERSION: "v1",
    KMS_AUTH_TOKEN: AUTH_TOKEN,
    KMS_KEY_V1: KEY_V1,
    REQUIRE_MTLS: "false",
    TRANSIT_KEY_NAME: "vault-root",
    TRANSIT_MOUNT_PATH: "transit",
    ...overrides,
  };
}

function request(
  operation: "encrypt" | "decrypt",
  body: unknown,
  token = AUTH_TOKEN,
): Request {
  return new Request(
    `https://kms.vault.platform.scg.sh/v1/transit/${operation}/vault-root`,
    {
      method: "PUT",
      headers: {
        "content-type": "application/json",
        "x-vault-token": token,
      },
      body: JSON.stringify(body),
    },
  );
}

async function responseBody(response: Response): Promise<any> {
  return response.json();
}

describe("Vault Transit compatibility", () => {
  test("reports health only when the current key and token are configured", async () => {
    const healthy = await handleRequest(
      new Request("https://kms.vault.platform.scg.sh/healthz"),
      environment(),
    );
    expect(healthy.status).toBe(200);
    expect(await responseBody(healthy)).toEqual({ status: "ok" });

    const unhealthy = await handleRequest(
      new Request("https://kms.vault.platform.scg.sh/healthz"),
      environment({ KMS_KEY_V1: undefined }),
    );
    expect(unhealthy.status).toBe(503);
  });

  test("requires the Vault token", async () => {
    const response = await handleRequest(
      request("encrypt", { plaintext: btoa("barrier key") }, "wrong-token"),
      environment(),
    );
    expect(response.status).toBe(403);
    expect(await responseBody(response)).toEqual({ errors: ["permission denied"] });
  });

  test("encrypts and decrypts a Transit payload", async () => {
    const plaintext = btoa("Vault barrier key material");
    const encryptedResponse = await handleRequest(
      request("encrypt", { plaintext }),
      environment(),
    );
    expect(encryptedResponse.status).toBe(200);

    const encryptedBody = await responseBody(encryptedResponse);
    expect(encryptedBody.data.ciphertext).toMatch(
      /^vault:v1:[A-Za-z0-9_-]+$/,
    );

    const decryptedResponse = await handleRequest(
      request("decrypt", { ciphertext: encryptedBody.data.ciphertext }),
      environment(),
    );
    expect(decryptedResponse.status).toBe(200);
    expect(await responseBody(decryptedResponse)).toEqual({
      data: { plaintext },
    });
  });

  test("uses a fresh AES-GCM nonce for every encryption", async () => {
    const body = { plaintext: btoa("same plaintext") };
    const first = await responseBody(
      await handleRequest(request("encrypt", body), environment()),
    );
    const second = await responseBody(
      await handleRequest(request("encrypt", body), environment()),
    );
    expect(first.data.ciphertext).not.toBe(second.data.ciphertext);
  });

  test("retains decryption support for old key versions", async () => {
    const plaintext = btoa("wrapped with v1");
    const oldEnvironment = environment({ KMS_KEY_V2: KEY_V2 });
    const encrypted = await responseBody(
      await handleRequest(
        request("encrypt", { plaintext }),
        oldEnvironment,
      ),
    );

    const rotatedEnvironment = environment({
      CURRENT_KEY_VERSION: "v2",
      KMS_KEY_V2: KEY_V2,
    });
    const decrypted = await handleRequest(
      request("decrypt", { ciphertext: encrypted.data.ciphertext }),
      rotatedEnvironment,
    );
    expect(decrypted.status).toBe(200);
    expect(await responseBody(decrypted)).toEqual({ data: { plaintext } });

    const newlyEncrypted = await responseBody(
      await handleRequest(
        request("encrypt", { plaintext }),
        rotatedEnvironment,
      ),
    );
    expect(newlyEncrypted.data.ciphertext).toMatch(/^vault:v2:/);
  });

  test("rejects tampered ciphertext without exposing crypto details", async () => {
    const encrypted = await responseBody(
      await handleRequest(
        request("encrypt", { plaintext: btoa("secret") }),
        environment(),
      ),
    );
    const ciphertext: string = encrypted.data.ciphertext;
    const payloadIndex = "vault:v1:".length;
    const replacement = ciphertext[payloadIndex] === "A" ? "B" : "A";
    const tampered =
      ciphertext.slice(0, payloadIndex) +
      replacement +
      ciphertext.slice(payloadIndex + 1);

    const response = await handleRequest(
      request("decrypt", { ciphertext: tampered }),
      environment(),
    );
    expect(response.status).toBe(400);
    expect(await responseBody(response)).toEqual({ errors: ["invalid ciphertext"] });
  });

  test("supports optional Cloudflare-verified client certificates", async () => {
    const noCertificate = await handleRequest(
      request("encrypt", { plaintext: btoa("secret") }),
      environment({ REQUIRE_MTLS: "true" }),
    );
    expect(noCertificate.status).toBe(401);

    const withCertificate = request("encrypt", {
      plaintext: btoa("secret"),
    }) as Request & {
      cf?: unknown;
    };
    withCertificate.cf = {
      tlsClientAuth: {
        certVerified: "SUCCESS",
        certRevoked: "0",
      },
    };
    const accepted = await handleRequest(
      withCertificate,
      environment({ REQUIRE_MTLS: "true" }),
    );
    expect(accepted.status).toBe(200);
  });

  test("does not expose APIs outside the configured Transit paths", async () => {
    const response = await handleRequest(
      new Request("https://kms.vault.platform.scg.sh/v1/transit/keys", {
        method: "GET",
      }),
      environment(),
    );
    expect(response.status).toBe(404);
  });
});
