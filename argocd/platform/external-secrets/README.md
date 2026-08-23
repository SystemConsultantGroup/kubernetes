한국어 | [English](README.en.md)

# External Secrets Operator

이 구성 요소는 관리형 애플리케이션 시크릿을 위한 External Secrets Operator를
설치합니다. 차트 버전은 [`../../../state.yaml`](../../../state.yaml)에 고정되어 있고
Helm release가 CRD를 설치합니다.

## 지원 범위

배포는 네임스페이스 범위 `SecretStore` 및 `ExternalSecret` 리소스를 처리합니다.
클러스터 범위 store, generator, push secret, ClusterExternalSecret은
비활성화되어 있습니다. 이를 통해 애플리케이션 연동을 네임스페이스 범위로 유지하고
클러스터 범위 시크릿 인터페이스 노출을 방지합니다.

플랫폼 소유 연동 gate가 활성화되면 관리형 애플리케이션 차트가 네임스페이스 범위
Vault SecretStore와 워크로드별 ExternalSecret 하나를 생성합니다. 애플리케이션
메타데이터는 Vault 서버, role, 경로를 구성하지 않습니다.
[Vault 계약](../vault/README.md)과
[애플리케이션 차트 문서](../../charts/application/README.md)를 참조하세요.

## 변경

차트 버전 고정을 `state.yaml`의 `external-secrets.version`과 동기화하세요.
다른 controller 또는 클러스터 범위 CRD 활성화는 권한 변경으로 취급하세요.
주 차트 버전을 변경하기 전에 CRD 업그레이드와 변환 호환성을 검증하세요.
ExternalSecret을 삭제하면 이 리소스가 소유한 Kubernetes Secret도 제거될 수
있습니다.
