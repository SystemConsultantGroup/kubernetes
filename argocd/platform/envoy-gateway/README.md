[English](README.en.md) | 한국어

# Envoy Gateway

이 Application은 버전이 고정된 Envoy Gateway 컨트롤러와 Envoy Gateway 전용
CRD를 설치합니다. 업스트림 Gateway API CRD의 소유권은 별도의
[`gateway-api`](../gateway-api/) Application에 있습니다.

Envoy Gateway는 `envoy-gateway` GatewayClass를 소유합니다. 공개
[`gateway-system/public`](../gateway/) Gateway는 이 클래스를 사용하며 Gateway
API `ListenerSet` 리소스를 통해 애플리케이션 리스너를 위임합니다.

Cilium은 클러스터 CNI, kube-proxy 대체 구현 및 네트워크 정책 엔진으로 계속
설치됩니다. Cilium values에서 `gatewayAPI`를 비활성화하는 것은 Cilium의
Gateway API 컨트롤러만 끄며 Cilium 네트워킹을 제거하지 않습니다.

공개 Envoy 데이터 플레인의 설정은 플랫폼 Gateway의 `EnvoyProxy` 리소스가
소유합니다. 공개 엔드포인트를 변경하기 전에 노출 방식, 노드 배치, 원본
클라이언트 IP 처리 및 Wasm 캐시 설정이 베어메탈 네트워킹과 맞는지 확인하세요.
