한국어 | [English](README.en.md)

# MySQL 플랫폼

이 Argo CD Application은 네임스페이스 범위 Percona operator와 별도로 `mysql`
namespace의 PXC 데이터베이스 클러스터를 소유합니다. operator는 이 namespace만
감시합니다. 각 클러스터는 `manifests/clusters/` 아래에 이름이 있는 manifest로
추가하고 `manifests/kustomization.yaml`에서 포함하세요.

## 클러스터

| 클러스터 | 용도 | PXC | XtraBackup | Service |
| --- | --- | --- | --- | --- |
| `central` | 과거에 신 통합DB라고 불린 데이터베이스의 migration target | `8.0.45-36.1` | `8.0.35-35.1` | `central-haproxy.mysql` |
| `alumni` | 동문 프로젝트용 새 데이터베이스 | `8.4.8-8.1` | `8.4.0-5.1` | `alumni-haproxy.mysql` |

`central`은 과거에 신 통합DB라고 불린 source의 target입니다. 별도의 구 통합 DB도
migration할지는 아직 결정되지 않았습니다. migration한다면 `central`에 함께 넣지
말고 별도로 검토된 identity를 부여하세요.

image version과 digest는 고정되어 있습니다. Alumni는 Percona Operator 1.20.0에서
인증된 PXC 8.4 및 XtraBackup version을 사용합니다. 자동 version 적용은 비활성화되어
upgrade가 별도로 검토되는 GitOps 변경으로 유지됩니다.

## 자격 증명 및 lifecycle 안전성

각 클러스터에는 고유한 `spec.secretsName`이 있습니다. Secret이 없으면 operator가
생성된 자격 증명으로 Secret을 만들고 PXC 시스템 사용자를 관리합니다. 같은 Secret을
선언적으로 만들거나 다른 controller가 소유권을 두고 경쟁하게 하지 마세요. 자격 증명
값을 커밋하거나 출력하지 말고 전체 Secret을 교체하는 대신 Percona가 지원하는 암호
교체 절차를 사용하세요.

모든 cluster CR에는 다음 두 보호 설정이 있습니다.

```yaml
argocd.argoproj.io/sync-options: Prune=false,Delete=false
```

manifest를 제거하거나 Argo CD Application을 삭제해도 데이터베이스 클러스터가 자동으로
삭제되면 안 됩니다. Decommission에는 client를 중지하고 recovery material을 확인하며
이 보호 설정을 의도적으로 제거하고 retained volume을 명시적으로 처리하는 별도의 검토
절차가 필요합니다.

## Topology 및 resource

두 클러스터는 현재 PXC 구성원 2개와 HAProxy instance 2개를 실행하며 필수 hostname
anti-affinity로 각각 하나씩 `k8s`와 `e2s`에 배치합니다. 두 size 관련 unsafe flag는
계속 필요합니다. 이는 과도기 topology이며 고가용성이 아닙니다. Galera quorum에는 두
PXC 구성원이 모두 필요하므로 어느 하나라도 손실되면 해당 클러스터를 사용할 수
없습니다. 구성원 장애 또는 무감독 rollout을 시험하지 마세요.

manifest는 CPU 및 memory request를 유지하지만 현재 의도적으로 resource limit을
설정하지 않습니다. 실제 workload를 측정한 뒤 검토된 limit을 추가하세요. 각 PXC
구성원은 retained 200 GiB `local-data` claim, 16 GiB memory, 12 GiB InnoDB buffer
pool을 요청합니다. hostPath provisioner는 PVC request를 filesystem quota로 강제하지
않으므로 각 data volume의 실제 사용량과 여유 공간을 모니터링하세요.

감독되는 2개 구성원 단계에서는 `RollingUpdate`를 유지합니다. 물리 노드 3대와 각
storage를 입증한 뒤 각 클러스터를 3개로 scale하고 `SmartUpdate`를 복원하세요. 엄격한
배치, SST, quorum, readiness 검사를 통과한 뒤에만 unsafe flag를 제거하세요.

## 데이터베이스 및 recovery 설정

PXC strict mode, 내구성 있는 transaction log 설정, UTF-8 기본값, source 호환 설정,
`+09:00` timezone이 명시되어 있습니다. Kubernetes reverse lookup 지연을 피하기 위해
DNS hostname resolution은 비활성화되어 있으므로 grant에는 DNS hostname 대신 `%`
또는 address pattern을 사용해야 합니다.

Backup 및 PITR 자격 증명에는 별도 Secret이 필요합니다. onsite S3 endpoint, bucket,
클러스터별 prefix, 자격 증명 범위가 승인될 때까지 추가하지 마세요. Backup restore,
PITR, 독립 offsite copy는 두 클러스터 모두의 production cutover 요구 사항입니다.
