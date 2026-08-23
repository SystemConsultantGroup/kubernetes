한국어 | [English](wait.en.md)

# wait

Talos 또는 Kubernetes 상태 검사가 성공할 때까지 기다립니다.

## 하위 명령

- `kubernetes`는 성공한 pod를 허용하고 모든 네임스페이스의 활성 pod가 Ready가 될
  때까지 기다립니다.
- `talos`는 선언된 모든 노드에 대해 Talos 상태 검사를 실행합니다.

## 사용법

```text
k wait <command> [args...]
```

`k wait`를 실행하면 하위 명령을 나열합니다.
이 페이지는 `k wait --help`로 확인하세요.

## 전제 조건

- `kubernetes`에는 연결 가능한 저장소 kubeconfig가 필요합니다.
- `talos`에는 저장소 talosconfig와 연결 가능한 선언된 노드가 필요합니다.

검사가 실패하거나 timeout이 발생하면 두 명령 모두 0이 아닌 상태를 반환합니다.
