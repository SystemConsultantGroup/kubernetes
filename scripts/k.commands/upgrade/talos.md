한국어 | [English](talos.en.md)

# talos

선언된 모든 노드의 Talos를 `state.yaml`의 `talos.version`으로 업그레이드합니다.

## 동작

이 명령은 각 노드를 검사하고 이미 대상 버전인 노드는 건너뜁니다.
업그레이드가 필요한 노드가 하나라도 있으면 `--yes`가 없는 경우 한 번 확인을 요청한
뒤, 고정된 installer 이미지와 `--wait`를 사용하여 `state.yaml` 순서대로 남은
노드를 한 번에 하나씩 업그레이드합니다.
마지막에 `k wait talos`를 실행합니다.

## 사용법

```bash
k upgrade talos [--yes]
```

## 전제 조건

- 저장소 talosconfig를 통해 `state.yaml`의 모든 노드에 연결할 수 있습니다.
- `state.yaml`에 대상 Talos 버전과 schematic이 있습니다.
- 대상 installer 이미지를 사용할 수 있습니다.

installer 이미지 형식은
`factory.talos.dev/installer/<schematic>:<version>`입니다.
업그레이드 중 노드가 재부팅될 수 있습니다. 한 번에 하나씩 진행되는 순서를 중단하지
마세요.
