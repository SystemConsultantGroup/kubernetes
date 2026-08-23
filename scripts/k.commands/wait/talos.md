한국어 | [English](talos.en.md)

# talos

`state.yaml`의 모든 노드에 Talos API로 직접 연결할 수 있을 때까지 기다린 뒤 선언된
전체 control plane 집합을 대상으로 클러스터 상태를 검사합니다.

## 동작

이 명령은 주 endpoint를 통한 클러스터 discovery에 의존하지 않고 먼저 선언된 각
노드에 직접 연결합니다. 각 Talos API를 최대 10분간 기다린 뒤 선언된 모든 주소를
명시적인 control plane 노드로 하나의 `talosctl health` 검사에 전달합니다. 이를 통해
참여하지 못한 노드가 discovery에서 조용히 누락되는 일을 방지합니다.

서비스 시작 중 출력되는 상태 오류에는 예상된 일시적 출력이라는 표시를 붙입니다.
직접 API가 준비되지 않거나 클러스터 상태 검사가 실패하면 0이 아닌 값을 반환합니다.

## 사용법

```bash
k wait talos
```

## 전제 조건

- 저장소 루트에 `talosconfig`가 있습니다. `k ensure talosconfig`로 확보하세요.
- `state.yaml`의 모든 노드에 연결할 수 있습니다.

이 명령은 인자를 받지 않으며 상태 검사가 실패하면 0이 아닌 값을 반환합니다.
