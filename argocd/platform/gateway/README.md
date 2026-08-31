한국어 | [English](README.en.md)

# 공개 Gateway

이 디렉터리는 플랫폼 서비스와 관리형 애플리케이션이 사용하는 Cilium 기반
`gateway-system/public` Gateway와 ingress 정책을 정의합니다. Cilium과 고정된
Gateway API CRD는 `k install cilium`으로 부트스트랩된 뒤 각각의 Argo CD
Application이 조정합니다.

## Listener

| Listener | 호스트 이름 | 인증서 |
| --- | --- | --- |
| `platform-https` | `*.platform.scg.sh` | `platform-wildcard-tls` |
| `testing-https` | `*.testing.scg.sh` | `application-wildcards-tls` |
| `preview-https` | `*.preview.scg.sh` | `application-wildcards-tls` |

cert-manager는 참조된 Secret을 `gateway-system`에 생성합니다. 관리형 프로덕션
도메인은 애플리케이션 차트가 생성한 ListenerSet을 통해 연결하며, 플랫폼이 TLS를
소유하는 경우 별도 인증서를 사용합니다.

## 클라이언트 네트워크 경계

`public-gateway-ingress` Cilium 정책은 `115.145.150.0/24`에서만 테스팅 및 프리뷰
호스트에 대한 인터넷 접근을 허용합니다. 클러스터 내부에서 시작된 트래픽은 계속
허용됩니다. 플랫폼 호스트는 공개 상태를 유지하며,
`application-routing-policies` ApplicationSet은 관리형 프로덕션 도메인에 대한
정확한 공개 호스트 규칙을 생성합니다. 다른 인터넷 소스 주소에서 테스팅 또는
프리뷰 호스트로 보낸 요청에는 Envoy `403 Forbidden` 응답이 반환됩니다.

정책은 Cilium의 예약된 ingress identity를 선택합니다. 정책을 변경할 때 CIDR 규칙과
공개 테스팅 또는 프리뷰 호스트 규칙이 없다는 조건을 모두 유지하세요. 기본 정책에
명시된 프로덕션 호스트는 enforcement 도입 시 존재한 애플리케이션을 위한 rollout
보호 장치입니다. 새 프로덕션 호스트의 규칙은 생성된 정책에서 제공합니다.

## 네임스페이스 경계

라우트와 ListenerSet은 다음 label이 지정된 네임스페이스에서만 연결할 수 있습니다.

```yaml
gateway.scg.sh/public: "true"
```

관리형 애플리케이션 네임스페이스는 ApplicationSet에서 이 label을 받습니다.
selector는 공개 노출 경계의 일부입니다. 검토되지 않은 라우트를 연결하기 위한
목적으로 범위를 넓히지 마세요.

## 변경 및 진단

라우트가 트래픽을 제공하려면 승인된 parent, 일치하는 listener 호스트 이름, 유효한
backend reference가 있어야 합니다. DNS를 검사하기 전에 Gateway 및 라우트 condition을
확인하세요. DNS 게시와 인증서 발급은 별도 controller이며
[`../external-dns-scg.sh/`](../external-dns-scg.sh/) 및
[`../cert-manager/`](../cert-manager/)에 문서화되어 있습니다.
