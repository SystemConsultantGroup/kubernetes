한국어 | [English](README.en.md)

# Local path provisioner

이 플랫폼 구성 요소는 `local-data` StorageClass용 노드 로컬 PersistentVolume을
동적으로 provision합니다. 변경 불가능한 upstream 커밋으로 고정된 Rancher Local
Path Provisioner를 사용합니다.

이 class는 의도적으로 클러스터 기본값이 아닙니다. 워크로드가 명시적으로 요청해야
합니다.

```yaml
storageClassName: local-data
```

볼륨은 `WaitForFirstConsumer`로 binding되므로 로컬 경로를 만들기 전에 스케줄링에서
노드를 선택합니다. 이 class는 Kubernetes 노드 `k8s`와 `e2s`를 허용하며 각 노드의
준비된 Talos `data` 사용자 볼륨의 다음 경로에 데이터를 저장합니다.

```text
/var/mnt/data
```

목록에 없는 노드에는 provisioning 경로가 없습니다. SCC에 유지된 Vault claim은 이
provisioning 경로가 변경되기 전에 이전 `EPHEMERAL` 경로에서 migration되었습니다.
E2S는 사용자 볼륨, 마운트, 노드 간 Cilium datapath를 확인한 뒤에만 추가되었습니다.
다른 노드도 동일한 storage 및 network 검사를 완료한 뒤에만 추가하세요.

reclaim policy는 `Retain`입니다. claim을 삭제해도 로컬 데이터가 지워지거나
PersistentVolume을 자동으로 재사용할 수 있게 되지 않습니다. 운영자는
PersistentVolume을 삭제하거나 교체하기 전에 유지된 데이터를 검사하고 정리해야
합니다.

요청된 PVC 용량은 스케줄링 메타데이터이며 강제되는 hostPath quota가 아닙니다.
워크로드는 사용자 볼륨의 가용 용량까지 요청량보다 더 많이 사용할 수 있습니다.
파일 시스템 사용량을 모니터링하고 복구, 임시 데이터, 유지된 다른 claim을 위한 공유
여유 공간을 보존하세요.

로컬 볼륨은 복제되지 않으며 다른 노드로 이동할 수 없습니다. Talos `STATE` 및
`EPHEMERAL`을 reset해도 별도로 선언된 사용자 볼륨은 지워지지 않지만 해당 data RAID가
손실되거나 지워지면 볼륨도 파괴됩니다. 애플리케이션은 자체 복제 또는 클러스터 외부
백업을 제공하고 노드 로컬 가용성을 감수해야 합니다.
