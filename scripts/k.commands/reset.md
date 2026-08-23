한국어 | [English](reset.en.md)

# reset

Talos 노드의 `STATE` 및 `EPHEMERAL` 파티션을 초기화한 뒤 재부팅합니다.

> [!CAUTION]
> 데이터를 파괴하는 작업입니다.
> 선택한 두 시스템 파티션의 노드 로컬 데이터가 손실되고 노드가 재부팅됩니다.
> 먼저 노드 이름과 의도한 복구 절차를 확인하세요.

## 동작

노드 인자가 없으면 `state.yaml`의 `.endpoint`가 선택한 주 노드를 대상으로 합니다.
노드 인자가 있으면 해당 노드 이름이 `state.yaml`에 선언되어 있어야 합니다.
`talosctl reset`을 non-graceful reset으로 실행하며 `STATE`와 `EPHEMERAL` 시스템
label만 초기화합니다. 별도로 선언된 Talos 사용자 볼륨은 이 명령의 대상이 아닙니다.
SCC의 `local-data` 경로는 별도 `data` 사용자 볼륨에 있지만 reset 전에 항상 각 대상
노드의 실제 저장소를 확인하세요.

`--yes`를 지정하지 않으면 명령이 확인을 요청합니다.
reset 전에 `k ensure talosconfig`를 실행하여 로컬 자격 증명이 선언된 클러스터와
일치하도록 합니다.

## 사용법

```bash
k reset [--yes] [node]
```

## 전제 조건

- 대상 노드가 `state.yaml`에 선언되어 있습니다.
- `talosconfig`를 확보할 수 있도록 `secrets/talos.yaml`을 복호화할 수 있습니다.
- Talos client 구성으로 대상에 연결할 수 있습니다.

`--yes`는 명시적으로 검토한 자동화 작업을 위한 옵션이며 확인 질문만 생략합니다.
