한국어 | [English](README.en.md)

# ApplicationSet

이 ApplicationSet은 `main`의 경로를 Argo CD Application으로 변환합니다.
[`../kustomization.yaml`](../kustomization.yaml)에 포함됩니다. 워크로드 Application은
`applications` AppProject를 사용합니다. Envoy Gateway listener 및 보안 정책은
`gateway` 구성 요소의 플랫폼 소유 리소스입니다.

## Generator

| 리소스 | 검색하는 파일 | 결과 |
| --- | --- | --- |
| `application-instances-static` | `applications/*/instances/production.yaml` 및 `testing.yaml` | 공유 애플리케이션 차트 |
| `application-instances-dynamic` | `applications/*/instances/preview/*/*.yaml` | 프리뷰 워크로드 하나를 사용하는 공유 차트 |
| `application-kustomize` | `applications/*/kustomization.yaml` | 애플리케이션 디렉터리를 직접 렌더링 |

관리형 메타데이터와 안정 인스턴스 잠금 파일은 별도 values 파일로 공유 차트에
전달됩니다.
프리뷰 잠금 파일은 `source`와 `image`만 제공하며 워크로드와 풀 리퀘스트 번호는
경로에서 가져옵니다.

관리형 generator는 활성화된 중앙 Vault 연동 gate와 신뢰하는 서버 URL을
소유합니다. 애플리케이션 메타데이터는 이 gate를 제어하거나 Vault 경로를 제공하지
않습니다. 계약과 활성화 절차는
[Vault 구성 요소 README](../platform/vault/README.md)에 문서화되어 있습니다.

## 새로 고침 동작

GitHub push webhook은 Argo CD API server와 ApplicationSet controller를 즉시 새로
고칩니다.
두 controller는 서로 다른 webhook 경로를 사용합니다.
Webhook이 지연되거나 사용할 수 없을 때를 대비해 Git polling은 180초 간격으로 계속
활성화합니다.

## 생성되는 식별자

애플리케이션 이름은 생성되는 모든 식별자의 첫 번째 구성 요소입니다.

| 애플리케이션 유형 | Argo CD Application | Helm release | 대상 네임스페이스 |
| --- | --- | --- | --- |
| 프로덕션 | `<application>-production` | `<application>-production` | `<application>-production` |
| 테스팅 | `<application>-testing` | `<application>-testing` | `<application>-testing` |
| 프리뷰 | `<application>-preview-<workload>-<pull-request>` | 동일 | 동일 |
| 사용자 정의 Kustomize | `<application>` | 없음 | `<application>` |

Argo CD Application 객체 자체는 `argocd` 네임스페이스에 있습니다.
저장소 검사는 ApplicationSet 조정 전에 Kubernetes 이름 제한을 초과하는 식별자를
거부합니다. 관리형 애플리케이션 리소스 이름은
[`../charts/application/README.md`](../charts/application/README.md)에 문서화되어
있습니다.

Application 또는 대상 네임스페이스 이름을 바꾸면 Argo CD 식별자가 변경되어 새
항목이 조정되기 전에 이전 Application과 네임스페이스가 정리될 수 있습니다.
이름 변경은 실제 migration 작업으로 취급하고 병합 전에 예상되는 삭제 및 재생성
동작을 검토하세요.

## 편집 규칙

- 각 애플리케이션에는 한 레이아웃만 사용하고 두 generator가 같은 경로를 검색하지
  않도록 합니다.
- GitOps 정책을 의도적으로 변경하는 경우가 아니라면 저장소 URL과 `main` 리비전을
  유지합니다.
- generator, 프로젝트, 네임스페이스, sync policy 변경은 플랫폼 전체 변경으로
  취급합니다.

생성된 각 Application은 자동 sync, 정리, 자동 복구, 네임스페이스 생성을
활성화합니다. 관리형 Application은 Reloader의 pod template annotation을 무시하므로
Secret으로 시작된 rolling deployment가 Argo CD 자동 복구와 충돌하지 않습니다.
애플리케이션 네임스페이스에는 공개 Gateway 라우트와 제한된 pod security에 필요한
label이 지정됩니다.

`applications` AppProject의 권한은
[`../projects/README.md`](../projects/README.md)를 참조하세요.
