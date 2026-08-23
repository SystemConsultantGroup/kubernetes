한국어 | [English](README.en.md)

# cert-manager

이 구성 요소는 cert-manager와 공개 Gateway에서 사용하는 인증서를 설치합니다.
[`../../../state.yaml`](../../../state.yaml)에 고정된 차트 버전을 사용하며 CRD 설치와
Gateway API 지원을 모두 활성화합니다.

## 발급

`zerossl-cloudflare` ClusterIssuer는 Cloudflare를 통해 ZeroSSL ACME DNS-01
challenge를 완료합니다. Application이 조정되기 전에 `k install argocd`가 다음 필수
Secret을 생성합니다.

- `cert-manager/cloudflare-api-token`
- `cert-manager/zerossl-eab`

매니페스트는 `gateway-system`에 두 개의 Secret을 발급합니다.

| Secret | 포함하는 이름 |
| --- | --- |
| `platform-wildcard-tls` | `*.platform.scg.sh` |
| `application-wildcards-tls` | `*.testing.scg.sh`, `*.preview.scg.sh` |

external로 표시되지 않은 관리형 프로덕션 도메인은 애플리케이션 차트에서 별도
Certificate를 받습니다.

## 변경 및 진단

차트 버전 고정을 `state.yaml`의 `cert-manager.version`과 동기화하세요.
issuer, ACME 계정, DNS provider, wildcard 이름 변경은 플랫폼 전체 인증서
migration입니다. Certificate를 진단하기 전에 issuer를 확인하고, 그다음
CertificateRequest, Order, Challenge 리소스를 확인하세요.
EAB HMAC 키나 Cloudflare 토큰을 이 매니페스트 또는 values에 절대 넣지 마세요.
