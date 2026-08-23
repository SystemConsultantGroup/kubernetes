한국어 | [English](kubernetes.en.md)

# kubernetes

Kubernetes control plane을 `state.yaml`의 `kubernetes.version`으로
업그레이드합니다.

## 동작

이 명령은 Kubernetes 서버 버전을 대상과 비교합니다.
일치하면 변경 없이 종료합니다.
그렇지 않으면 주 노드에 대해 Talos dry run을 실행하고, `--yes`가 없으면 확인을
요청한 뒤 해당 노드에 업그레이드를 적용하고 선언된 모든 노드의 Talos 및 Kubernetes
상태가 정상화될 때까지 기다립니다.
dry run이 성공해야 확인 질문이 나타납니다.

## 사용법

```bash
k upgrade kubernetes [--yes]
```

## 전제 조건

- 저장소 kubeconfig를 통해 클러스터에 연결할 수 있습니다.
- `talosconfig`로 `state.yaml`이 선택한 주 노드에 연결할 수 있습니다.
- `state.yaml`에 `kubernetes.version`이 있습니다.
- Talos가 대상 Kubernetes 버전을 지원합니다.

이 명령은 `state.yaml`을 변경하지 않습니다. 실행 전에 고정된 버전을 갱신하고
검토하세요.
