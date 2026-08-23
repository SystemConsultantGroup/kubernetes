한국어 | [English](README.en.md)

# Percona PXC Operator

이 플랫폼 구성 요소는 Percona XtraDB Cluster 기반 MySQL용 Percona Operator를
설치합니다. Helm 차트와 operator는 버전 1.20.0으로 고정되어 있습니다.

operator는 `mysql`에서 실행되며 해당 네임스페이스만 감시합니다. PXC 클러스터는
별도 Argo CD Application이므로 custom resource, 자격 증명, 저장소, 백업 policy를
독립적으로 검토할 수 있습니다. 실수로 Git에서 삭제하여 operator와 CRD가 제거되는
일을 방지하기 위해 이 Application의 루트 리소스는 자동 정리에서 제외됩니다.

operator 자체는 데이터베이스를 만들지 않으며 이 디렉터리에는 자격 증명이 없습니다.
데이터베이스, operator, 백업 자격 증명은 검토된 네임스페이스 범위 ExternalSecret
리소스 또는 승인된 다른 워크플로에서 가져와야 합니다.

루트 Application은 wave 1의 로컬 저장소 이후인 sync wave 2에서 이 child를
생성합니다. 향후 PXC Application은 더 뒤의 wave를 사용해야 하며 Argo CD가
`/var/mnt/data` local provisioner 경로를 조정하기 전에는 claim을 생성하면 안 됩니다.

PXC custom resource가 하나라도 존재하는 동안 operator 또는 CRD를 제거하지 마세요.
버전을 변경하기 전에 고정된 차트를 렌더링하고 검사한 뒤 operator 업그레이드와 PXC
데이터베이스 버전 변경을 별도로 수행하세요.
