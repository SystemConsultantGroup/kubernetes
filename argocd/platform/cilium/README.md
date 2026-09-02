한국어 | [English](README.en.md)

# Cilium

Cilium은 클러스터 네트워크, kube-proxy replacement, 네트워크 정책 및 eBPF enforcement를
제공합니다. Gateway API 구현은 Envoy Gateway가 소유하며 Cilium은 CNI와 네트워크 정책
엔진으로 계속 사용됩니다. 차트 버전은 `state.yaml`에 고정되어 있으며 Application
리비전이 해당 버전 고정과 일치해야 합니다.

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
cgroup, `localhost:7445`의 KubePrism 및 명시적 capability가 포함됩니다. Cilium의
Gateway API controller는 플랫폼 Gateway를 Envoy Gateway가 관리하므로 비활성화되어
있습니다.

Cilium Envoy는 Envoy Gateway가 host-network public proxy를 소유하므로 비활성화되어
있습니다. 클러스터에는 남아 있는 Cilium L7 정책이 없으며, 같은 listener node에서
host-network Envoy 구현을 동시에 활성화하지 마세요.
