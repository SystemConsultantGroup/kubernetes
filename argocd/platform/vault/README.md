한국어 | [English](README.en.md)

# Vault

이 구성 요소는 공식 Helm 차트, 통합 Raft 저장소,
`kms.vault.platform.scg.sh`의 Transit 호환 Cloudflare Worker를 통한 자동 봉인 해제를
사용하여 HashiCorp Vault를 배포합니다.

현재 클러스터에는 물리 노드가 하나뿐이므로 단일 Raft 구성원은 내구성이 있지만
고가용성은 아닙니다. 독립적인 노드와 저장소를 사용할 수 있기 전에는
`server.ha.replicas`를 늘리지 마세요.

## 저장소 및 TLS

Vault는 유지되는 `local-data` 볼륨 두 개를 요청합니다.

- 통합 Raft 저장소용 `/vault/data`의 10 GiB
- file audit log용 `/vault/audit`의 10 GiB

두 볼륨 모두 노드 로컬입니다. PersistentVolume은 `Retain`을 사용하며 별도로 선언된
Talos `data` 사용자 볼륨의 `/var/mnt/data`에 있습니다. 저장소의 `k reset` 명령은
이 사용자 볼륨이 아니라 `STATE`와 `EPHEMERAL`만 초기화합니다. SCC data RAID가
손실되거나 지워지면 두 볼륨 모두 파괴됩니다.

cert-manager는 `vault.platform.scg.sh`용 `vault-server-tls`를 발급합니다. 공개
Gateway는 client TLS를 종료하고 `BackendTLSPolicy`를 사용하여
`vault-active:8200`에 대한 두 번째 TLS 연결을 수립하고 검증합니다. 공개 ZeroSSL
issuer chain은 `vault-backend-ca`에 고정되어 있습니다. cert-manager가 issuer
chain을 변경하면 이 bundle을 갱신하세요.

## Transit seal 자격 증명

[`../../../secrets/vault.yaml`](../../../secrets/vault.yaml)은 다음 항목의 암호화된
사본을 저장합니다.

- Vault와 Worker의 `KMS_AUTH_TOKEN` binding이 공유하는
  `VAULT_TRANSIT_SEAL_TOKEN`
- Worker의 `KMS_KEY_V1` binding을 복구하기 위한 사본인
  `VAULT_TRANSIT_SEAL_KEY_V1`

`k initialize vault`는 Kubernetes 토큰을 `vault/vault-transit-seal`로 생성합니다.
Worker 복구 값은 표준 입력을 통해서만 이동해야 합니다.

```bash
sops decrypt --extract '["VAULT_TRANSIT_SEAL_KEY_V1"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_KEY_V1)
sops decrypt --extract '["VAULT_TRANSIT_SEAL_TOKEN"]' secrets/vault.yaml |
  (cd workers/kms && bun run wrangler secret put KMS_AUTH_TOKEN)
```

Vault 초기화 후에는 `KMS_KEY_V1`을 절대 교체하지 마세요. Worker 키 교체 절차를
따르고 이전 버전을 유지하세요.

## 초기화

Argo CD와 Worker가 준비된 뒤 installer를 실행하세요.

```bash
k initialize vault
```

새 데이터 볼륨에서는 Vault를 초기화하고, 일회성 응답을 즉시
`secrets/vault-recovery.yaml`에 SOPS로 암호화하고, auditing, KV v2, Kubernetes
인증, 공유 관리형 애플리케이션 접근을 구성합니다. Vault 데이터 볼륨을 의도적으로
교체한 뒤에는 변경된 암호화 복구 파일을 커밋하세요. 초기화된 Vault에서는 기존 파일을
검증하고 유지합니다.

installer는 복구 파일에 유효한 초기 root 토큰이 있는 동안에만 권한 있는 Vault
구성을 조정합니다. 해당 토큰을 폐기하고 제거한 뒤 커밋된 policy 또는 인증을
변경하려면 플랫폼 운영자가 인증하고 명시적으로 계획한 작업으로 적용해야 합니다.
installer를 다시 실행해도 해당 설정을 조정하지 않습니다.

복구 파일은 현재 Raft 데이터에 연결된 생성 출력입니다. 이 파일의 share는 Worker
키를 대신하지 않으며 해당 키를 잃으면 Vault 봉인을 해제할 수 없습니다.

## 운영자 인증

Vault는 Argo CD에 포함된 Dex를 OIDC provider로 사용합니다. Dex는 기존 GitHub OAuth
애플리케이션에 인증을 위임하고 GitHub 팀 claim을 발급합니다. 연결은 다음과 같습니다.

- `SystemConsultantGroup:active`는 `github-active`를 받아 `kv/` 아래의 시크릿 값과
  버전을 관리합니다.
- `SystemConsultantGroup:platform`은 Vault를 관리하는 `github-platform`을 받습니다.

`platform` 팀은 `active` 아래에 중첩되어 있으므로 플랫폼 운영자는 두 policy를 모두
받습니다. Vault에는 `secrets/bootstrap.yaml`의 별도 Dex client secret이 있으며
Argo CD의 downstream session이나 client identity를 재사용하지 않습니다.

인증되지 않은 Vault UI는 OIDC를 기본 방식으로 표시하고 break-glass 접근을 위한
토큰 로그인을 **Other** 아래에 유지합니다. CLI에서는 다음을 사용하세요.

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
```

OIDC 토큰의 TTL은 1시간이고 갱신할 수 있으며 최대 TTL은 8시간입니다. 활성 운영자
세션 중에는 브라우저 로그인을 반복하지 말고 `vault token renew`를 사용하세요.

초기 root 토큰을 폐기하고 `vault-recovery.yaml`에서 제거하기 전에 플랫폼 로그인을
테스트하세요. Dex 또는 GitHub를 사용할 수 없을 때 복구 share가 break-glass
메커니즘으로 남습니다. 현재 배포의 초기 root 토큰은 폐기되고 제거된 상태입니다.

## 애플리케이션 접근

Vault 부트스트랩은 모든 관리형 애플리케이션 SecretStore를 위한 `applications`
Kubernetes auth role 및 policy를 하나씩 생성합니다. role은 모든 네임스페이스의
`vault-auth` ServiceAccount를 허용하며 `kv/data/applications/` 아래의 세 구간 경로를
모두 읽을 수 있습니다.

애플리케이션 onboarding은 Vault 구성을 변경하지 않습니다. 생성된 SecretStore와
ExternalSecret은 [애플리케이션 차트 문서](../../charts/application/README.md)에
설명된 공유 role과 파생 경로를 사용합니다. 따라서 애플리케이션 및 환경 분리는 Vault
권한 부여 경계가 아니라 생성된 경로 규칙이며, 차트 또는 인증 변경에는 여전히 플랫폼
검토가 필요합니다.

### 애플리케이션 값 관리

GitHub `active` 팀 구성원은 OIDC 로그인 후 Vault UI에서 값을 관리할 수 있습니다.
다음 KV v2 경로를 사용하세요.

| 인스턴스 | 경로 |
| --- | --- |
| 프로덕션 | `kv/applications/<application>/production/<workload>` |
| 테스팅 | `kv/applications/<application>/testing/<workload>` |
| 프리뷰 재정의 | `kv/applications/<application>/preview/<workload>` |

프리뷰는 먼저 테스팅 경로를 읽은 뒤 공유 프리뷰 경로를 덮어씁니다. 프리뷰 경로는
풀 리퀘스트별 경로가 아닙니다. 경로가 없어도 허용되며 생성된 환경 Secret은 존재하지
않습니다. 값을 변경하면 External Secrets가 Kubernetes Secret을 새로 고치고
Reloader가 영향을 받는 관리형 Deployment를 rolling restart합니다.

`DATABASE_URL` 같은 이식 가능한 환경 변수 키를 사용하세요. 승인된 시크릿 처리
워크플로를 통해 값을 입력하세요. 평문 값을 Git, 셸 기록, 명령 출력, 문서에 넣지
마세요.

## 운영

운영자 명령에는 공개 주소를 사용하세요.

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault status
```

이 저장소는 인프라를 복원하지만 Vault 데이터는 복원하지 않으며 Raft snapshot을
포함하지 않습니다. 별도 data 사용자 볼륨은 `k reset` 후에도 유지되지만 해당 볼륨을
지우거나 잃으면 새로운 Raft 데이터와 대체 `vault-recovery.yaml`이 필요합니다.
노드 로컬 볼륨을 유일한 복구 사본으로 사용하기 전에 전용 암호화 백업 시스템과
테스트된 복원 절차를 추가하세요.
