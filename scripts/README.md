한국어 | [English](README.en.md)

# 운영자 명령

[`k`](k)는 로컬 클러스터 작업을 위한 플랫폼 운영자 진입점입니다.
애플리케이션 개발자 워크플로의 일부가 아닙니다. 저장소 개발 셸에서 시작하세요.

```bash
nix develop
k --help
```

이 셸은 `scripts/`를 `PATH`에 추가하고 저장소의 주요 도구를 제공하며,
`TALOSCONFIG`와 `KUBECONFIG`가 저장소 루트의 무시된 파일을 가리키도록
설정합니다. 도움말과 암호화된 시크릿 관리는 클러스터 상태를 불러오지 않으므로
`state.yaml`을 복구하는 중에도 사용할 수 있습니다.

## 명령 그룹

| 명령 | 용도 |
| --- | --- |
| `k secrets` | 암호화된 값을 검증 및 편집하고 age 수신자 관리 |
| `k ensure` | 로컬 Talos 및 Kubernetes 자격 증명 검증 및 복구 |
| `k render` | 상태에서 파생된 스키마와 Kubernetes 매니페스트 렌더링 |
| `k install` | Kubernetes, Cilium, Argo CD GitOps 루트 부트스트랩 |
| `k initialize` | 권한 있는 API 호출이 필요한 상태 저장 서비스 초기화 |
| `k apply` | 선언된 모든 노드에 Talos 패치 적용 |
| `k upgrade` | `state.yaml`의 버전으로 Talos 또는 Kubernetes 업그레이드 |
| `k reset` | Talos 노드 초기화 및 재부팅 |
| `k wait` | Talos 또는 Kubernetes 상태가 정상화될 때까지 대기 |
| `k forward` | Argo CD를 localhost로 포트 포워딩 |

작업 직전에 `k <command> --help`를 사용하세요. 각 페이지에는 전제 조건, 인자,
부작용, 확인 동작이 설명되어 있습니다. 해당 문서는
[`k.commands/`](k.commands/)에 있습니다.

안전하게 시작할 수 있는 일반적인 명령은 다음과 같습니다.

```bash
k secrets check
k render application-schemas --check
k render manifests
nix flake check
```

저장소 검사는 [`checks/`](checks/)에 있습니다. 클러스터에 접근하지 않으며 운영자
명령도 아닙니다.

## 로컬 산출물

`k ensure talosconfig`와 `k ensure kubeconfig`는 저장소 루트에 로컬 자격 증명을
기록합니다. `k render manifests`는 검사 가능한 비밀이 아닌 출력을
`.rendered/`에 기록합니다. 이 경로들은 로컬 상태를 사용하고 Git에서 무시되며,
환경 세부 정보가 포함된 경우 이슈나 풀 리퀘스트에 복사하면 안 됩니다.

## 안전

`k install`, `k initialize`, `k apply`, `k upgrade`, `k reset`은 실제
클러스터를 변경할 수 있습니다. 먼저 [`../state.yaml`](../state.yaml), 노드 패치,
관련 명령 도움말을 검토하세요. `k reset`은 Talos `STATE` 및 `EPHEMERAL` 데이터를
초기화합니다.
