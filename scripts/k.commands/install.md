한국어 | [English](install.en.md)

# install

Argo CD GitOps 루트를 생성하여 클러스터를 부트스트랩합니다.

## 사용법

```bash
k install
k install <command>
```

하위 명령 없이 `k install`을 실행하면 다음 순서로 전체 부트스트랩을 수행합니다.

1. Talos 구성, Kubernetes, etcd를 설치합니다.
1. Gateway API와 Cilium 부트스트랩 매니페스트를 렌더링하고 적용합니다.
1. 클러스터 네트워크를 기다립니다.
1. Argo CD, 부트스트랩 자격 증명, 루트 Application을 렌더링하고 적용합니다.

명령은 GitOps 경계에서 중지합니다. 이후에는 루트 Application이 Cilium,
Gateway API, Argo CD, 기타 플랫폼 구성 요소, 애플리케이션 워크로드를 조정합니다.
플랫폼 Application을 사용할 수 있게 된 뒤 새 Vault 저장소는
`k initialize vault`로 별도 초기화하세요.

## 하위 명령

- `kubernetes`는 Talos 구성, Kubernetes, etcd, 로컬 자격 증명을 설치합니다.
- `cilium`은 Argo CD가 실행되기 전에 CNI와 Gateway API 정의를 부트스트랩합니다.
- `argocd`는 Argo CD, 필수 Secret, GitOps 루트를 부트스트랩합니다.

## 전제 조건

전체 부트스트랩에는 다음이 필요합니다.

- 암호화된 모든 Talos 및 부트스트랩 시크릿을 복호화할 수 있고 실제 값이 있습니다.
- 선언된 모든 노드에 `patches/<node>.yaml`이 있습니다.
- `patches/worker.yaml`과 `patches/cilium.yaml`이 있습니다.
- 고정된 Gateway API, Cilium, Argo CD 산출물에 접근할 수 있습니다.

전체 명령은 클러스터를 변경하기 전에 부트스트랩 값과 모든 Talos 입력을 검증합니다.
첫 번째 실패에서 중지하며 부분 실패 후 개별 단계를 다시 실행할 수 있습니다.
실제 클러스터를 변경하는 작업이며 확인 질문은 없습니다.
