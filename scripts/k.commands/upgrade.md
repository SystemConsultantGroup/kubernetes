한국어 | [English](upgrade.en.md)

# upgrade

Talos가 관리하는 구성 요소를 `state.yaml`에 고정된 버전으로 업그레이드합니다.

## 하위 명령

- `kubernetes`는 Kubernetes control plane을 업그레이드합니다.
- `talos`는 선언된 모든 노드의 Talos를 업그레이드합니다.

## 사용법

```bash
k upgrade <kubernetes|talos> [--yes]
```

Cilium, Gateway API, Argo CD, 기타 플랫폼 구성 요소는 Argo CD 목표 상태입니다.
한 풀 리퀘스트에서 `state.yaml`과 일치하는 GitOps 리비전을 함께 변경하여
업그레이드하세요. 저장소 검사는 일치하지 않는 버전 고정을 거부합니다.

명령형 Talos 및 Kubernetes 명령은 설치된 버전을 확인하고 이미 최신이면 변경 없이
종료합니다. `--yes`를 지정하지 않으면 `[y/N]`으로 확인을 요청합니다. 업그레이드
중 노드가 재부팅될 수 있으므로 `--yes`는 검토된 자동화 옵션으로 취급하세요.
