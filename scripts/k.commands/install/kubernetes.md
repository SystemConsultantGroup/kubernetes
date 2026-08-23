한국어 | [English](kubernetes.en.md)

# kubernetes

Talos에 Kubernetes를 설치하고 로컬 자격 증명을 확보합니다.

## 동작

이 명령은 다음 단계를 순서대로 실행합니다.

1. `talosconfig`가 `state.yaml` 및 암호화된 Talos 시크릿과 일치하도록 합니다.
1. 선언된 모든 노드에 `k apply`를 실행합니다.
1. 주 노드가 아직 etcd 구성원이 아니면 etcd를 부트스트랩합니다.
1. 모든 노드의 Talos 및 Kubernetes 상태가 정상화될 때까지 기다립니다.
1. 저장소 루트 `kubeconfig`로 API에 연결할 수 있도록 합니다.

etcd 부트스트랩은 최대 10분 동안 10초마다 재시도합니다. Talos가 시작되는 동안
재시도에서 출력되는 연결 오류에는 예상된 오류라는 표시가 붙습니다. 첫 부팅에서
`k apply`는 인증되지 않은 machine-status endpoint가 Talos maintenance 모드임을
확인한 경우에만 `--insecure`를 사용합니다. 연결할 수 없는 노드나 그 밖의 인증
실패가 발생하면 설치를 중단합니다.

## 사용법

```bash
k install kubernetes
```

## 전제 조건

- 로컬 age 키로 `secrets/talos.yaml`을 복호화할 수 있습니다.
- 선언된 모든 노드에 `patches/<node>.yaml`과 공유 worker 및 Cilium 패치가 있습니다.
- `state.yaml`에 Talos schematic, Talos 버전, Kubernetes 버전이 고정되어 있습니다.
- 선언된 노드 주소가 정확하고 구성을 적용할 때 노드 전원이 켜져 있습니다. 첫 부팅
  노드는 insecure 경로를 사용할 수 있습니다.

이 명령은 인자를 받지 않고 실제 노드와 클러스터를 변경합니다.
`talosconfig`와 `kubeconfig`는 mode `600`으로 기록됩니다.
