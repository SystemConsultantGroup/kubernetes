한국어 | [English](README.en.md)

# MySQL 플랫폼

이 Argo CD Application은 Percona operator와 별도로 PXC 클러스터의 네임스페이스
범위 리소스를 소유합니다. Percona operator가 PXC 시스템 사용자 자격 증명의
기준이며 Vault와 External Secrets는 데이터베이스 부트스트랩 의존성이 아닙니다.

클러스터는 `spec.secretsName`을 `pxc-system-users`로 고정합니다. 해당 Secret이
없으면 operator가 생성된 자격 증명으로 Secret을 만들고 PXC 시스템 사용자를
관리합니다. 같은 Secret을 선언적으로 생성하거나 소유권을 두고 경쟁하는 다른
controller를 도입하지 마세요.

`pxc-system-users`를 민감한 데이터베이스 상태로 취급하세요. 값을 커밋하거나
출력하지 마세요. 기존 데이터베이스 데이터를 이동하거나 복원하기 전에 승인된 암호화
백업 워크플로로 보존하고 전체 Secret을 교체하는 대신 Percona가 지원하는 암호 교체
절차를 사용하세요.

백업 및 PITR 자격 증명에는 별도 Secret이 필요합니다. onsite S3 endpoint, bucket,
자격 증명 범위가 승인될 때까지 추가하지 마세요. 애플리케이션 데이터베이스 사용자도
별도의 최소 권한 Secret이 필요합니다. 애플리케이션은 PXC 시스템 계정을 사용하면
안 됩니다.

`mysql` PerconaXtraDBCluster는 SCC의 PXC 구성원 하나와 HAProxy 하나를 사용하는
명시적으로 안전하지 않은 rehearsal로 시작합니다. PXC 8.0.45를 사용하고
`pxc-system-users`를 참조하며 `argocd.argoproj.io/sync-options: Prune=false`를
지정합니다. 데이터베이스는 유지되는 250 GiB `local-data` claim, 16 GiB 메모리,
12 GiB InnoDB buffer pool을 요청합니다. 로컬 hostPath provisioning은 250 GiB
요청을 파일 시스템 quota로 강제하지 않으므로 저장소 모니터링으로 공유 데이터 볼륨의
여유 공간을 보호해야 합니다.

단일 구성원 및 단일 proxy 크기에는 `unsafeFlags.pxcSize`와
`unsafeFlags.proxySize`가 모두 필요합니다. 이 토폴로지를 고가용성으로 취급하지
마세요. 이 rehearsal은 준비된 다른 구성원 없이 `SmartUpdate`가 restart를 안전하게
진행할 수 없으므로 `RollingUpdate`를 사용합니다. 프로덕션 전환 전에 백업 복원과
offsite 복제를 입증하세요. 물리 노드 세 대가 모두 준비되면 SCC 전용 selector를
제거하고 두 크기를 모두 3으로 설정하고 `SmartUpdate`를 복원한 뒤 unsafe flag를
제거하기 전에 엄격한 호스트 이름 anti-affinity를 확인하세요.

PXC strict mode, 내구성 있는 transaction log 설정, 소스 문자 설정, 소스 시간대는
사용자 정의 MySQL 구성에 명시되어 있습니다. Kubernetes reverse lookup 지연을 피하기
위해 DNS 호스트 이름 확인은 비활성화되어 있으므로 사용자 grant에는 DNS 호스트 이름
대신 `%` 또는 주소 패턴을 사용해야 합니다. 데이터베이스 버전 변경이 별도로 검토되는
GitOps 작업으로 유지되도록 업그레이드 검사는 비활성화되어 있습니다.
