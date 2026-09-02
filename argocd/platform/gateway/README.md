한국어 | [English](README.en.md)

# 공개 Gateway

이 디렉터리는 플랫폼 서비스와 관리형 애플리케이션이 사용하는 Envoy Gateway 기반
`gateway-system/public` Gateway와 리스너 정책을 정의합니다. Cilium은 클러스터 CNI와
네트워크 정책 엔진으로 계속 사용하며, Gateway API controller와 Envoy 데이터 플레인은
Envoy Gateway가 소유합니다.

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

`testing-access` 및 `preview-access` Envoy Gateway `SecurityPolicy` 리소스는
`115.145.150.0/24`에서 시작한 외부 클라이언트만 허용합니다. 현재 클러스터
PodCIDR인 `10.244.0.0/23`도 명시적으로 허용하므로 클러스터 내부 클라이언트는
제한된 listener를 사용할 수 있습니다. 플랫폼 및 관리형
프로덕션 호스트는 공개 상태입니다. 프로덕션 호스트 라우팅은 관리형 애플리케이션
차트가 계속 생성합니다.

정책은 Cilium identity가 아니라 공유 Gateway의 listener section을 대상으로 합니다.
제한된 listener를 변경할 때 default-deny 동작과 source CIDR을 유지하세요. Envoy 앞에
proxy나 load balancer가 배치되면 클라이언트 IP 처리가 실제 클라이언트 주소를 계속
사용하는지도 확인해야 합니다.

## 네임스페이스 경계

라우트와 ListenerSet은 다음 label이 지정된 네임스페이스에서만 연결할 수 있습니다.

```yaml
gateway.scg.sh/public: "true"
```

관리형 애플리케이션 네임스페이스는 ApplicationSet에서 이 label을 받습니다.
selector는 공개 노출 경계의 일부입니다. 검토되지 않은 라우트를 연결하기 위한
목적으로 범위를 넓히지 마세요. Envoy Gateway의 `GatewayClass`와 `EnvoyProxy`
리소스는 플랫폼이 소유합니다.

## Wasm 가져오기 호환성

Envoy Gateway는 HTTP Wasm 모듈을 내부 `envoy-gateway` Service를 통해 제공합니다.
이 클러스터는 IPv4 전용이므로 공유 proxy의 해당 내부 cluster에는 IPv4 전용 DNS를
사용하도록 patch를 적용합니다. 그렇지 않으면 Envoy의 dual-stack DNS resolver가
`wasm_cluster`에 healthy host를 남기지 않아 애플리케이션 route에 도달하기 전에 HTTP
503을 반환할 수 있습니다.

## 변경 및 진단

라우트가 트래픽을 제공하려면 승인된 parent, 일치하는 listener 호스트 이름, 유효한
backend reference가 있어야 합니다. DNS를 검사하기 전에 Gateway, ListenerSet, 정책,
라우트 condition을 확인하세요. Envoy 데이터 플레인 Service 또는 host-networked
DaemonSet에도 예상한 공개 엔드포인트가 있어야 합니다. DNS 게시와 인증서 발급은
별도 controller이며 [`../external-dns-scg.sh/`](../external-dns-scg.sh/) 및
[`../cert-manager/`](../cert-manager/)에 문서화되어 있습니다.
