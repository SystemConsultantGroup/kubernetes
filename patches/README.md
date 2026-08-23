한국어 | [English](README.en.md)

# Talos 머신 패치

이 디렉터리에는 모든 노드에 사용하는 Talos 구성 조각이 있습니다.
`k` 명령은 control plane 머신 구성을 생성하기 전에 선택한 노드 패치를 공유 worker
및 Cilium 패치와 결합합니다.

## 파일

| 파일 | 범위 |
| --- | --- |
| `worker.yaml` | control plane 노드의 워크로드 스케줄링을 포함한 공유 worker 설정 |
| `cilium.yaml` | Talos CNI와 kube-proxy를 사용하지 않기 위한 공유 Cilium 전제 조건 |
| `<node>.yaml` | 노드별 호스트 이름, 디스크 선택자, 사용자 볼륨 |

현재 노드별 파일은 `scc.yaml`, `e1s.yaml`, `e2s.yaml`입니다.
[`../state.yaml`](../state.yaml)에 나열된 모든 노드에는 대응하는 파일이 필요하며,
주석 처리된 노드는 활성화할 때까지 무시합니다.
현재 상태에서는 `scc`와 `e2s`가 활성화되어 있습니다.

## 디스크 선택자

`machine.install.diskSelector.wwid`는 시스템 디스크를 선택합니다.
설치 또는 적용 전에 대상 머신에서 WWID를 확인하세요.
노드를 활성화하기 전에 `REPLACE_WITH_E1S_SYSTEM_DISK_WWID` 같은 자리표시자를
교체하세요.

`scc`와 `e2s` 패치는 선택한 디스크에 `data`라는 파티션 기반 Talos 사용자
볼륨도 선언하며 `/var/mnt/data`에 마운트합니다. 선택자는 안정적인 WWID를 사용하고
각 디스크의 사용 가능한 공간까지 확장하도록 요청합니다. 두 경로 중 하나에
워크로드를 배정하기 전에 실제 Talos 볼륨과 마운트 상태를 확인하세요.

이곳에 자격 증명을 넣지 마세요.
Talos 시크릿은 암호화된
[`../secrets/talos.yaml`](../secrets/talos.yaml)에 유지합니다.

## 변경 적용

`k apply`는 구성을 노드에 하나라도 적용하기 전에 모든 구성을 다시 생성하고
검증합니다. `state.yaml`의 노드에 영향을 주는 실제 작업이며 dry-run 모드는
없습니다. 실행 전에 대상 노드, 디스크 선택자, 생성될 구성을 검토하세요.
Kubernetes 설치에도 같은 패치 집합을 사용합니다.
