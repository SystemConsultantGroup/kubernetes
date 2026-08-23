한국어 | [English](README.en.md)

# Cilium

Cilium은 클러스터 네트워크, kube-proxy replacement, Gateway API 구현을 제공합니다.
차트 버전은 `state.yaml`에 고정되어 있으며 Application 리비전이 해당 버전 고정과
일치해야 합니다.

## 부트스트랩 및 소유권

Argo CD pod를 실행하려면 정상적인 CNI가 필요합니다. 따라서 부트스트랩 중
`k install cilium`이 고정된 Gateway API 및 Cilium 매니페스트를 렌더링하고
적용합니다. 루트 Application이 생기면 이 Application이 정리와 자동 복구를 사용하여
같은 Cilium 차트와 values를 조정합니다.

부트스트랩 후에는 Git에서 버전과 values를 변경하고 Argo CD가 업그레이드하도록
하세요. 목표 상태의 두 번째 소스를 만들 수 있으므로 Cilium CLI를 사용하지 마세요.

## Talos 설정

values는 [`../../../patches/cilium.yaml`](../../../patches/cilium.yaml)에 설정된
Talos 요구 사항을 유지합니다. Kubernetes IPAM, kube-proxy replacement, host
cgroup, `localhost:7445`의 KubePrism, 명시적 capability, host-networked Gateway
Envoy, ALPN, appProtocol 지원이 포함됩니다. 네트워크를 변경할 때 Talos 패치와 이
values를 함께 검토하세요.

## 공개 listener 배치

Host-networked Gateway listener는 다음 label이 지정된 노드에서만 실행됩니다.

```text
gateway.scg.sh/listener=true
```

Cilium은 선택한 노드 주소를 Gateway status에 게시하고 ExternalDNS는 공개 라우트를
위해 해당 주소를 게시할 수 있습니다. 외부 연결, Cilium 상태, Gateway 트래픽을
테스트한 뒤에만 노드에 이 label을 추가하세요. 이 listener selector와 관계없이
Cilium agent와 Envoy DaemonSet은 사용 가능한 모든 Kubernetes 노드에서 계속
실행됩니다.
