한국어 | [English](README.en.md)

# Vault KMS Worker

이 Cloudflare Worker는 HashiCorp Vault의 `seal "transit"` 자동 봉인 해제
백엔드에 필요한 최소 Vault Transit HTTP API를 구현합니다.
`kms.vault.platform.scg.sh`에서 실행하도록 설계되었습니다.

의도적으로 범용 Transit 서버 기능은 제공하지 않습니다. 다음 작업만 지원합니다.

```text
PUT|POST /v1/transit/encrypt/vault-root
PUT|POST /v1/transit/decrypt/vault-root
GET      /healthz
```

암호화에는 매번 새로 생성한 96비트 nonce와 AES-256-GCM을 사용합니다. 암호문은
Transit 호환 형식인 `vault:vN:<base64url>`을 따르며 키 버전을 추가 데이터로
인증합니다. Worker는 요청 상태를 보관하지 않습니다.

## 보안 모델

암호화 키와 API 토큰은 Cloudflare secret binding입니다. Wrangler와 대시보드에서는
값이 숨겨지지만 Worker 코드는 접근할 수 있습니다. 따라서 이 Worker에 수정된 코드를
배포할 수 있는 사람은 키를 유출할 수도 있습니다. 독립적으로 호스팅되는 자동 봉인
해제 서비스로는 유용하지만, 내보낼 수 없는 키를 사용하는 HSM 또는 KMS와 동등하지는
않습니다.

Cloudflare 배포 자격 증명을 Kubernetes 및 Vault 자격 증명과 별도로 보호하세요.
요청 본문 로깅을 활성화하지 마세요. 모든 키 버전을 오프라인 접근 통제 백업에
보관하세요. Vault 데이터를 보호하는 키를 잃으면 Vault를 복구하지 못할 수 있습니다.

Transit endpoint에 대한 모든 요청에는 구성된 공유 시크릿이 `X-Vault-Token`에
있어야 합니다. mTLS는 향후 심층 방어 고려 사항입니다. 활성화하려면 해당 호스트
이름에 대한 Cloudflare client certificate 검증이 필요합니다.

## 로컬 개발

저장소 개발 셸에 들어가 잠긴 의존성을 설치하고 검사를 실행하세요.

```bash
nix develop
cd workers/kms
bun install --frozen-lockfile
bun run check
```

`bun run dev`를 실행하기 전에 `.dev.vars.example`을 `.dev.vars`로 복사하고 두 값을
모두 교체하세요. `.dev.vars`는 Git에서 무시됩니다.

`KMS_KEY_V1`은 암호학적으로 안전한 무작위 바이트 정확히 32개를 표준 base64로
인코딩한 값이어야 합니다. 신뢰할 수 있는 CSPRNG로 생성하고 원래 값을 플랫폼 암호
관리자 또는 승인된 다른 오프라인 복구 위치에 보관하세요.

## Cloudflare 구성

`platform.scg.sh`를 소유한 Cloudflare 계정으로 Wrangler를 인증한 뒤 값을 명령줄에
넣지 않고 secret binding을 생성하세요.

```bash
bun run wrangler secret put KMS_AUTH_TOKEN
bun run wrangler secret put KMS_KEY_V1
```

토큰은 길고 무작위인 값이어야 합니다. 키는 위에서 설명한 base64 인코딩이어야
합니다. 두 시크릿이 모두 존재하는 것을 확인한 뒤에만 배포하세요.

```bash
bun run deploy
```

`wrangler.jsonc`는 `kms.vault.platform.scg.sh`를 Custom Domain으로 생성하고 공개
`workers.dev` 및 프리뷰 URL을 비활성화합니다. 서비스를 `kms.platform.scg.sh`로
이동한다면 Custom Domain과 Vault `address`를 함께 변경하세요. 초기화된 Vault에서
계획된 seal migration 없이 Transit mount 또는 키 이름을 변경하지 마세요.

### 향후 고려 사항: mTLS

현재 mTLS는 비활성화되어 있습니다. 더 강한 심층 방어가 필요해지면 custom domain에
Cloudflare API Shield client certificate 검증을 구성하고 Vault가 해당 인증서를
제시하도록 구성하세요. 그런 다음 `wrangler.jsonc`의 `REQUIRE_MTLS`를 정확히
`true`로 설정하고 다시 배포하세요. `true`와 `false`만 허용되므로 오타가 있으면
요청이 안전하게 실패합니다. Worker는 Cloudflare의 `certVerified` 값이 `SUCCESS`인지
확인하고 폐기된 인증서를 거부합니다. 토큰 인증을 두 번째 요소로 계속 활성화하세요.

## Vault 구성

`KMS_AUTH_TOKEN`에 저장한 것과 같은 토큰을 Kubernetes Secret을 통해 Vault에
`VAULT_TRANSIT_SEAL_TOKEN`으로 제공하세요.

```hcl
seal "transit" {
  address         = "https://kms.vault.platform.scg.sh"
  token           = "env://VAULT_TRANSIT_SEAL_TOKEN"
  disable_renewal = "true"

  mount_path = "transit"
  key_name   = "vault-root"
}
```

이 Worker는 의도적으로 Vault 토큰 갱신을 구현하지 않으므로 `disable_renewal`은
true로 유지해야 합니다. 초기화된 Vault에 이 seal을 추가할 때는 Vault에 문서화된
seal migration 절차를 사용하세요. Worker 또는 키를 사용할 수 없을 때는 복구 키로
Vault의 봉인을 해제할 수 없습니다.

## 키 교체

키 교체는 배포를 통해 수행하며 HTTP 관리 API는 없습니다.

1. 새로운 32바이트 키를 생성하고 백업합니다.
1. `wrangler secret put`으로 `KMS_KEY_V2`를 추가합니다. `KMS_KEY_V1`은 유지합니다.
1. `wrangler.jsonc`의 `CURRENT_KEY_VERSION`을 `v2`로 변경하고 배포합니다.
1. 중요하지 않은 Vault 노드 하나를 재시작하고 자동 봉인 해제를 확인한 뒤 나머지
   노드에 순차 적용합니다.
1. 저장된 Vault 암호문을 보호할 가능성이 있는 모든 이전 key binding을 유지합니다.

단조롭게 증가하는 이름(`KMS_KEY_V3` 등)으로 반복하세요. 기존 버전의 값을 절대
교체하지 마세요.

## 검증

```bash
bun run typecheck
bun test
bun run wrangler deploy --dry-run
```

테스트는 인증, Transit 응답 호환성, 무작위 암호문, 변조 거부, mTLS 강제 적용,
키 교체 전후의 복호화를 다룹니다.
