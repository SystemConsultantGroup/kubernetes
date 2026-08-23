한국어 | [English](cilium.en.md)

# cilium

Argo CD를 실행하기 전에 고정된 Gateway API 정의와 Cilium을 부트스트랩합니다.

## 동작

이 명령은 `k render manifests`를 실행한 뒤 렌더링된 Gateway API 및 Cilium
부트스트랩 매니페스트를 server-side apply로 적용합니다. 둘 다
`argocd-controller` field manager를 사용하므로 루트 Application이 경쟁하는 명령형
manager 없이 지속적인 소유권을 인계받을 수 있습니다. 모든 Cilium pod가 Ready를
보고할 때까지 기다립니다.

공유 values는 Kubernetes IPAM, kube-proxy replacement, Gateway API,
host-networked Envoy, 저장소에 필요한 Talos 보안 및 cgroup 설정을 활성화합니다.

## 사용법

```bash
k install cilium
```

## 전제 조건

- Kubernetes가 설치되어 있고 저장소 kubeconfig를 통해 연결할 수 있습니다.
- `state.yaml`에 Gateway API 및 Cilium 버전이 있습니다.
- 고정된 release와 차트에 네트워크로 접근할 수 있습니다.

이 명령은 인자를 받지 않고 클러스터 범위 리소스를 변경합니다. Argo CD 부트스트랩
후에는 업그레이드를 위해 이 명령을 다시 실행하지 말고 Git 목표 상태를 통해 Cilium과
Gateway API를 갱신하세요.
