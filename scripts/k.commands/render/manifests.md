한국어 | [English](manifests.en.md)

# manifests

상태에서 파생된 Kubernetes 매니페스트를 적용하지 않고 렌더링합니다.

## 출력

이 명령은 무시된 `.rendered/` 디렉터리를 원자적으로 다시 생성합니다.

| 경로 | 내용 |
| --- | --- |
| `bootstrap/gateway-api.yaml` | 고정된 Gateway API 표준 CRD |
| `bootstrap/cilium.yaml` | 고정된 Cilium 차트와 공유 Talos 호환 values |
| `bootstrap/argocd.yaml` | 고정된 Argo CD 차트와 저장소 values |
| `gitops/root.yaml` | 루트 Argo CD Kustomization |
| `gitops/platform/` | 저장소 로컬 플랫폼 Kustomization |
| `applications/` | 모든 사용자 정의 및 관리형 애플리케이션 인스턴스 |

부트스트랩 렌더링은 `state.yaml`의 구성 요소 버전을 사용합니다. Argo CD는 운영자
명령 없이 저장소를 읽으므로 GitOps Application에 원격 리비전이 반복됩니다. 저장소
검사는 해당 리비전이 `state.yaml`과 일치하도록 강제합니다.

## 사용법

```bash
k render manifests
```

## 전제 조건

- `nix develop` 안에서 실행합니다.
- GitHub와 Cilium 및 Argo CD Helm 저장소에 네트워크로 접근할 수 있습니다.
- 애플리케이션 및 플랫폼 소스 파일을 로컬에서 렌더링할 수 있습니다.

이 명령은 인자를 받지 않습니다. 로컬에서 무시되는 출력인 `.rendered/`를 교체할 수
있습니다. 클러스터 자격 증명을 사용하거나 클러스터를 변경하지 않습니다.
