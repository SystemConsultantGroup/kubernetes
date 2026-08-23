한국어 | [English](README.en.md)

# example

이 관리형 애플리케이션은
[`SystemConsultantGroup/kubernetes-example`](https://github.com/SystemConsultantGroup/kubernetes-example)의
최소 Node.js 서비스를 배포합니다. `example.scg.sh`를 공개하고 포트 8080에서
`/readyz` 프로브를 실행합니다.

프로덕션, 테스팅, 프리뷰 잠금 파일은 변경 불가능한 소스 커밋과 컨테이너 다이제스트를
사용합니다. 공유 애플리케이션 차트가 `fe` 워크로드에 해당하는 Deployment와
Service를 생성합니다.

이 애플리케이션은 모든 환경에서 Vault 연동을 확인합니다. 응답은 생성된 시크릿의
동작을 전체 프로세스 환경을 반환하지 않고 확인할 수 있도록 선택한 환경 변수 다섯
개만 노출합니다.

민감하지 않은 예시 값은 환경 격리와 프리뷰 계층 적용을 보여 줍니다.

| 변수 | 프로덕션 | 테스팅 | 프리뷰 결과 |
| --- | --- | --- | --- |
| `EXAMPLE_MESSAGE` | `Hello from production` | `Hello from testing` | `Hello from preview` |
| `ENVIRONMENT` | `production` | `testing` | `preview` |
| `INHERITED_VALUE` | `production-independent` | `inherited-from-testing` | `inherited-from-testing` |
| `OVERRIDDEN_VALUE` | `production` | `testing-base` | `preview-override` |
| `PREVIEW_ONLY_VALUE` | 설정 안 됨 | 설정 안 됨 | `only-from-preview` |

프리뷰는 먼저 테스팅 경로를 읽고 그다음 프리뷰 경로를 읽습니다. 따라서
`INHERITED_VALUE`를 상속하고, 세 값을 재정의하며, `PREVIEW_ONLY_VALUE`를
추가합니다.
