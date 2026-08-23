한국어 | [English](README.en.md)

# Argo CD 프로젝트

Argo CD Project는 Application이 사용할 수 있는 저장소, 대상, Kubernetes 리소스를
제한합니다.
이 파일들은 권한 부여 경계이며 생성된 Application 및 플랫폼 Application보다 먼저
적용됩니다.

## 프로젝트

| 프로젝트 | 소스 | 리소스 범위 |
| --- | --- | --- |
| `applications` | 이 저장소 | 모든 네임스페이스, `Namespace` 및 모든 네임스페이스 범위 kind |
| `platform` | 이 저장소 및 승인된 upstream 플랫폼 차트와 매니페스트 저장소 | 모든 네임스페이스 및 플랫폼 서비스에 필요한 클러스터 범위 kind |

정확한 allowlist는 [`applications.yaml`](applications.yaml)과
[`platform.yaml`](platform.yaml)을 참조하세요. `applications` 대상은 생성되는
네임스페이스를 위해 충분히 넓어야 하므로 저장소 레이아웃 검사와 플랫폼 검토도 각
사용자 정의 애플리케이션이 자신의 네임스페이스만 대상으로 하도록 강제합니다.
AppProject는 병합된 목표 상태 검토를 대체하지 않습니다.

## 편집 지침

프로젝트 변경은 권한 변경으로 취급하세요.
소스를 추가할 때는 해당 저장소가 필요한지 확인하세요.
대상이나 리소스 kind를 추가할 때는 구성 요소를 지원하는 가장 좁은 변경을 하세요.
검토를 우회하거나 애플리케이션 워크로드에 플랫폼 전용 접근 권한을 부여하기 위해
프로젝트를 변경하지 마세요.

두 프로젝트 모두 sync wave `0`을 사용하며 ApplicationSet과 플랫폼 Application은
그 이후에 실행됩니다.
부트스트랩 의존성 그래프를 의도적으로 변경하는 경우가 아니라면 이 순서를 유지하세요.
