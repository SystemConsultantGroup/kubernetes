한국어 | [English](kubernetes.en.md)

# kubernetes

모든 네임스페이스의 활성 pod가 Ready가 될 때까지 최대 10분간 기다립니다.

## 동작

이 명령은 모든 pod를 polling합니다. Succeeded 상태인 pod는 완료되었으므로 Ready
조건이 필요하지 않습니다. 실패한 pod가 있으면 즉시 중단하고, 그 밖의 모든 pod는
기한 전에 Ready를 보고해야 합니다.

선택적인 구성 요소 이름은 진행 메시지만 변경하며 검사를 해당 구성 요소로 제한하지
않습니다.

## 사용법

```bash
k wait kubernetes [component]
```

## 전제 조건

- `kubeconfig`가 있고 클러스터에 연결할 수 있습니다.

기본 구성 요소 label은 `Kubernetes`입니다.
pod가 실패하거나 활성 pod가 timeout 전에 Ready에 도달하지 못하면 명령이
실패합니다.
