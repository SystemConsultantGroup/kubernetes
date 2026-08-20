const encoder = new TextEncoder();
const MAX_REQUEST_BYTES = 64 * 1024;
const AES_GCM_IV_BYTES = 12;
const AES_GCM_TAG_BYTES = 16;
const KEY_VERSION_PATTERN = /^v[1-9][0-9]*$/;
const PATH_COMPONENT_PATTERN = /^[A-Za-z0-9_-]+(?:\/[A-Za-z0-9_-]+)*$/;

export interface Env {
  KMS_AUTH_TOKEN?: string;
  CURRENT_KEY_VERSION?: string;
  TRANSIT_KEY_NAME?: string;
  TRANSIT_MOUNT_PATH?: string;
  REQUIRE_MTLS?: string;
  [binding: string]: unknown;
}

interface TransitEncryptRequest {
  plaintext: string;
}

interface TransitDecryptRequest {
  ciphertext: string;
}

interface TlsClientAuth {
  certPresented?: string;
  certVerified?: string;
  certRevoked?: string;
}

type RequestWithCloudflare = Request & {
  cf?: {
    tlsClientAuth?: TlsClientAuth;
  };
};

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "cache-control": "no-store",
      "content-type": "application/json; charset=utf-8",
      "x-content-type-options": "nosniff",
    },
  });
}

function errorResponse(status: number, message: string): Response {
  return json({ errors: [message] }, status);
}

function setting(env: Env, name: string, fallback?: string): string {
  const value = env[name];
  if (typeof value === "string" && value.length > 0) {
    return value;
  }
  if (fallback !== undefined) {
    return fallback;
  }
  throw new HttpError(503, "KMS is not configured");
}

function booleanSetting(environment: Env, name: string, fallback: boolean): boolean {
  const value = setting(environment, name, fallback ? "true" : "false").toLowerCase();
  if (value === "true") {
    return true;
  }
  if (value === "false") {
    return false;
  }
  throw new HttpError(503, `KMS ${name} setting is invalid`);
}

function transitConfiguration(env: Env): {
  currentVersion: string;
  keyName: string;
  mountPath: string;
} {
  const currentVersion = setting(env, "CURRENT_KEY_VERSION", "v1");
  const keyName = setting(env, "TRANSIT_KEY_NAME", "vault-root");
  const mountPath = setting(env, "TRANSIT_MOUNT_PATH", "transit").replace(
    /^\/+|\/+$/g,
    "",
  );

  if (!KEY_VERSION_PATTERN.test(currentVersion)) {
    throw new HttpError(503, "KMS key version is invalid");
  }
  if (
    !PATH_COMPONENT_PATTERN.test(mountPath) ||
    !PATH_COMPONENT_PATTERN.test(keyName) ||
    keyName.includes("/")
  ) {
    throw new HttpError(503, "KMS Transit path is invalid");
  }

  return { currentVersion, keyName, mountPath };
}

function decodeStandardBase64(value: string): Uint8Array {
  if (
    value.length % 4 !== 0 ||
    !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(
      value,
    )
  ) {
    throw new Error("invalid base64");
  }

  const binary = atob(value);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function encodeStandardBase64(value: Uint8Array): string {
  let binary = "";
  for (const byte of value) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary);
}

function decodeBase64Url(value: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]+$/.test(value)) {
    throw new Error("invalid base64url");
  }

  const standard = value.replace(/-/g, "+").replace(/_/g, "/");
  const padding = "=".repeat((4 - (standard.length % 4)) % 4);
  return decodeStandardBase64(standard + padding);
}

function encodeBase64Url(value: Uint8Array): string {
  return encodeStandardBase64(value)
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

function toArrayBuffer(value: Uint8Array): ArrayBuffer {
  const copy = new Uint8Array(value.byteLength);
  copy.set(value);
  return copy.buffer;
}

async function sha256(value: string): Promise<Uint8Array> {
  return new Uint8Array(
    await crypto.subtle.digest("SHA-256", encoder.encode(value)),
  );
}

function constantTimeEqual(left: Uint8Array, right: Uint8Array): boolean {
  if (left.byteLength !== right.byteLength) {
    return false;
  }

  const subtle = crypto.subtle as SubtleCrypto & {
    timingSafeEqual?: (a: ArrayBufferView, b: ArrayBufferView) => boolean;
  };
  if (subtle.timingSafeEqual) {
    return subtle.timingSafeEqual(left, right);
  }

  let difference = 0;
  for (let index = 0; index < left.byteLength; index += 1) {
    difference |= left[index]! ^ right[index]!;
  }
  return difference === 0;
}

async function isAuthorized(request: Request, env: Env): Promise<boolean> {
  const expectedToken = setting(env, "KMS_AUTH_TOKEN");
  const suppliedToken = request.headers.get("x-vault-token") ?? "";
  const [expectedHash, suppliedHash] = await Promise.all([
    sha256(expectedToken),
    sha256(suppliedToken),
  ]);
  return constantTimeEqual(expectedHash, suppliedHash);
}

function hasValidClientCertificate(request: RequestWithCloudflare): boolean {
  const tls = request.cf?.tlsClientAuth;
  return tls?.certVerified === "SUCCESS" && tls.certRevoked === "0";
}

function keyBindingName(version: string): string {
  return `KMS_KEY_${version.toUpperCase()}`;
}

async function loadKey(env: Env, version: string): Promise<CryptoKey> {
  if (!KEY_VERSION_PATTERN.test(version)) {
    throw new HttpError(400, "invalid ciphertext");
  }

  const rawBinding = env[keyBindingName(version)];
  if (typeof rawBinding !== "string" || rawBinding.length === 0) {
    throw new HttpError(503, "required KMS key version is unavailable");
  }

  let keyBytes: Uint8Array;
  try {
    keyBytes = decodeStandardBase64(rawBinding);
  } catch {
    throw new HttpError(503, "KMS key is invalid");
  }
  if (keyBytes.byteLength !== 32) {
    throw new HttpError(503, "KMS key must contain exactly 32 bytes");
  }

  return crypto.subtle.importKey(
    "raw",
    toArrayBuffer(keyBytes),
    { name: "AES-GCM" },
    false,
    ["encrypt", "decrypt"],
  );
}

function additionalData(version: string): Uint8Array {
  return encoder.encode(`scg-vault-worker-kms\u0000${version}`);
}

async function encrypt(
  plaintextBase64: string,
  env: Env,
  version: string,
): Promise<string> {
  let plaintext: Uint8Array;
  try {
    plaintext = decodeStandardBase64(plaintextBase64);
  } catch {
    throw new HttpError(400, "plaintext must be standard base64");
  }

  const key = await loadKey(env, version);
  const iv = crypto.getRandomValues(new Uint8Array(AES_GCM_IV_BYTES));
  const encrypted = new Uint8Array(
    await crypto.subtle.encrypt(
      {
        name: "AES-GCM",
        iv: toArrayBuffer(iv),
        additionalData: toArrayBuffer(additionalData(version)),
        tagLength: AES_GCM_TAG_BYTES * 8,
      },
      key,
      toArrayBuffer(plaintext),
    ),
  );

  const payload = new Uint8Array(iv.byteLength + encrypted.byteLength);
  payload.set(iv);
  payload.set(encrypted, iv.byteLength);
  return `vault:${version}:${encodeBase64Url(payload)}`;
}

async function decrypt(ciphertext: string, env: Env): Promise<string> {
  const match = /^vault:(v[1-9][0-9]*):([A-Za-z0-9_-]+)$/.exec(ciphertext);
  if (!match) {
    throw new HttpError(400, "invalid ciphertext");
  }

  const [, version, encodedPayload] = match;
  let payload: Uint8Array;
  try {
    payload = decodeBase64Url(encodedPayload!);
  } catch {
    throw new HttpError(400, "invalid ciphertext");
  }
  if (payload.byteLength < AES_GCM_IV_BYTES + AES_GCM_TAG_BYTES) {
    throw new HttpError(400, "invalid ciphertext");
  }

  const key = await loadKey(env, version!);
  const iv = payload.slice(0, AES_GCM_IV_BYTES);
  const encrypted = payload.slice(AES_GCM_IV_BYTES);

  try {
    const plaintext = new Uint8Array(
      await crypto.subtle.decrypt(
        {
          name: "AES-GCM",
          iv: toArrayBuffer(iv),
          additionalData: toArrayBuffer(additionalData(version!)),
          tagLength: AES_GCM_TAG_BYTES * 8,
        },
        key,
        toArrayBuffer(encrypted),
      ),
    );
    return encodeStandardBase64(plaintext);
  } catch {
    throw new HttpError(400, "invalid ciphertext");
  }
}

async function readJson(request: Request): Promise<unknown> {
  const contentLength = request.headers.get("content-length");
  if (
    contentLength !== null &&
    Number.isFinite(Number(contentLength)) &&
    Number(contentLength) > MAX_REQUEST_BYTES
  ) {
    throw new HttpError(413, "request is too large");
  }

  const body = await request.text();
  if (encoder.encode(body).byteLength > MAX_REQUEST_BYTES) {
    throw new HttpError(413, "request is too large");
  }

  try {
    return JSON.parse(body);
  } catch {
    throw new HttpError(400, "request body must be JSON");
  }
}

async function health(env: Env): Promise<Response> {
  try {
    const { currentVersion } = transitConfiguration(env);
    setting(env, "KMS_AUTH_TOKEN");
    await loadKey(env, currentVersion);
    return json({ status: "ok" });
  } catch {
    return json({ status: "unavailable" }, 503);
  }
}

export async function handleRequest(request: Request, env: Env): Promise<Response> {
  try {
    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/healthz") {
      return health(env);
    }

    const { currentVersion, keyName, mountPath } = transitConfiguration(env);
    const encryptPath = `/v1/${mountPath}/encrypt/${keyName}`;
    const decryptPath = `/v1/${mountPath}/decrypt/${keyName}`;

    if (url.pathname !== encryptPath && url.pathname !== decryptPath) {
      return errorResponse(404, "not found");
    }
    if (request.method !== "PUT" && request.method !== "POST") {
      return errorResponse(405, "method not allowed");
    }

    if (
      booleanSetting(env, "REQUIRE_MTLS", false) &&
      !hasValidClientCertificate(request as RequestWithCloudflare)
    ) {
      return errorResponse(401, "client certificate required");
    }
    if (!(await isAuthorized(request, env))) {
      return errorResponse(403, "permission denied");
    }

    const body = await readJson(request);
    if (url.pathname === encryptPath) {
      if (
        typeof body !== "object" ||
        body === null ||
        typeof (body as TransitEncryptRequest).plaintext !== "string"
      ) {
        throw new HttpError(400, "plaintext is required");
      }
      const ciphertext = await encrypt(
        (body as TransitEncryptRequest).plaintext,
        env,
        currentVersion,
      );
      return json({ data: { ciphertext } });
    }

    if (
      typeof body !== "object" ||
      body === null ||
      typeof (body as TransitDecryptRequest).ciphertext !== "string"
    ) {
      throw new HttpError(400, "ciphertext is required");
    }
    const plaintext = await decrypt(
      (body as TransitDecryptRequest).ciphertext,
      env,
    );
    return json({ data: { plaintext } });
  } catch (error) {
    if (error instanceof HttpError) {
      return errorResponse(error.status, error.message);
    }
    return errorResponse(500, "internal error");
  }
}

export default {
  fetch: handleRequest,
};
