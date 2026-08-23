한국어 | [English](README.en.md)

# 공개 Gateway

이 디렉터리는 플랫폼 서비스와 관리형 애플리케이션이 사용하는 Cilium 기반
`gateway-system/public` Gateway를 정의합니다. Cilium과 고정된 Gateway API CRD는
`k install cilium`으로 부트스트랩된 뒤 각각의 Argo CD Application이 조정합니다.

## Listener

| Listener | 호스트 이름 | 인증서 |
| --- | --- | --- |
| `platform-https` | `*.platform.scg.sh` | `platform-wildcard-tls` |
| `testing-https` | `*.testing.scg.sh` | `application-wildcards-tls` |
| `preview-https` | `*.preview.scg.sh` | `application-wildcards-tls` |

cert-manager는 참조된 Secret을 `gateway-system`에 생성합니다. 관리형 프로덕션
도메인은 애플리케이션 차트가 생성한 ListenerSet을 통해 연결하며, 플랫폼이 TLS를
소유하는 경우 별도 인증서를 사용합니다.

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
