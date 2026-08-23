한국어 | [English](README.en.md)

# SCG Kubernetes

이 저장소는 단일 `scg` Kubernetes 클러스터의 목표 상태를 관리합니다.
애플리케이션 배포와 Talos, Cilium, Argo CD 플랫폼을 정의합니다.
Argo CD는 정리와 자동 복구를 활성화한 채 `main`을 추적하므로
[`applications/`](applications/) 또는 [`argocd/`](argocd/) 아래의 변경을
병합하면 실제 클러스터가 변경될 수 있습니다.

## 애플리케이션 담당자

[`applications/`](applications/)에서 작업한 뒤 풀 리퀘스트를 제출하세요.
애플리케이션마다 다음 레이아웃 중 정확히 하나만 사용합니다.

- 관리형 애플리케이션에는 `meta.yaml`과 `instances/` 아래의 변경 불가능한 파일이 있습니다.
- 사용자 정의 애플리케이션에는 루트 `kustomization.yaml`이 있습니다.

두 레이아웃을 섞거나 자격 증명을 커밋하지 마세요. 파일 형식, 예시, 프리뷰 동작,
검토 체크리스트는 [`applications/` 안내서](applications/)에서 확인하세요.
애플리케이션 개발자에게는 클러스터 자격 증명이나 플랫폼 전용 `k` 명령에 대한
접근 권한이 필요하지 않습니다.

## 플랫폼 운영자

플랫폼 운영자에게는 flakes가 활성화된 Nix가 필요합니다.
Nix가 아직 없다면 Determinate 설치 프로그램을 사용하는 것이 호환되는 구성을
준비하는 가장 쉬운 방법입니다.

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

Nix가 이미 설치되어 있다면 개발 셸에 들어가기 전에 flakes를 활성화하세요.
그런 다음 지원되는 환경에 들어가 작업별 도움말을 확인한 후 작업을 실행하세요.

```bash
nix develop
k --help
k <command> --help
```

일반적인 저장소 변경에는 실제 클러스터를 검증 환경으로 사용하지 말고 로컬 검사를
실행하세요.

```bash
nix fmt -- --ci .
nix flake check
```

이 셸은 지원되는 도구를 제공하고 `TALOSCONFIG`와 `KUBECONFIG`가 저장소 루트의
무시된 파일을 가리키도록 설정합니다.
로컬 age 키를 만들고 수신자를 출력하세요.

```bash
k secrets recipients me
```

암호화된 시크릿을 검사하기 전에 기존 운영자에게 해당 수신자를 추가해 달라고
요청하세요.

```bash
k secrets check
```

일상적인 목표 상태 작업에서는 저장소를 편집하고 로컬 검사를 실행한 뒤 풀 리퀘스트를
여세요. 매니페스트가 변경되었다는 이유만으로 install 또는 apply 명령을 실행하지
마세요. Argo CD가 병합된 목표 상태를 자동으로 조정합니다.

다음 명령은 클러스터를 변경할 수 있습니다.

```text
k install
k initialize vault
k apply
k upgrade <talos|kubernetes>
k reset [--yes] [node]
```

> [!CAUTION]
> 작업 전에 [`state.yaml`](state.yaml), 노드 주소, [`patches/`](patches/)의
> 디스크 선택자를 검토하세요. `k reset`은 선택한 노드의 Talos `STATE` 및
> `EPHEMERAL` 파티션을 초기화합니다.

Argo CD가 관리하는 리소스는 클러스터에서 직접 편집하지 말고 Git에서 변경하세요.

## 저장소 구성

- [`applications/`](applications/)에는 애플리케이션 메타데이터, 다이제스트로 고정된
  인스턴스 잠금 파일, 사용자 정의 Kustomization이 있습니다.
- [`argocd/`](argocd/)에는 GitOps 루트, ApplicationSet, 플랫폼 구성 요소,
  프로젝트, 공유 애플리케이션 차트가 있습니다.
- [`patches/`](patches/)에는 공통 및 노드별 Talos 패치가 있습니다.
- [`scripts/`](scripts/)는 운영자용 `k` 명령과 도움말을 제공합니다.
- [`secrets/`](secrets/)에는 공개 수신자 레지스트리와 암호화된 클러스터 구성이 있습니다.
- [`state.yaml`](state.yaml)은 클러스터 토폴로지와 버전의 기준이며, 저장소 검사는
  여러 곳에 반복된 매니페스트 버전 고정을 검증합니다.
- [`workers/`](workers/)에는 Argo CD 외부에서 배포되는 Cloudflare Worker가 있습니다.
- [`working/`](working/)에는 임시 조사 자료가 있으며, 구성 요소의 영구 계약은
  두지 않습니다.
