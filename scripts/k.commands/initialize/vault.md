한국어 | [English](vault.en.md)

# vault

Argo CD가 조정하는 Vault 배포를 초기화하고 구성합니다.

## 동작

이 명령은 다음 작업을 수행합니다.

1. 외부 KMS Worker가 정상인지 확인합니다.
1. `secrets/vault.yaml`에서 Transit 토큰을 복호화하고
   `vault/vault-transit-seal` Kubernetes Secret을 생성합니다.
1. Argo CD가 관리하는 Vault pod와 API를 기다립니다.
1. Vault가 초기화되지 않았다면 복구 share 5개와 threshold 3으로 초기화합니다.
1. 일회성 초기화 응답을 즉시 `secrets/vault-recovery.yaml`에 암호화합니다.
1. file audit device, `kv`의 KV v2, Kubernetes 인증을 활성화합니다.
1. 공유 관리형 애플리케이션 policy와 Kubernetes auth role을 생성합니다.
1. namespace 범위의 MySQL backup policy와 Kubernetes auth role을 생성합니다.
1. Argo CD Dex를 통한 GitHub 인증을 구성하고 기본 web UI 방식으로 지정하며,
   `active` 및 `platform` 팀을 Vault policy에 연결합니다.
1. `https://vault.platform.scg.sh/v1/sys/health`를 기다립니다.

Vault가 이미 초기화되어 있고 복구 파일에 유효한 초기 root 토큰이 남아 있으면
권한 있는 구성을 조정합니다. 해당 토큰을 폐기하고 제거한 뒤에는 권한 있는 조정을
시도하지 않고 복구 파일을 검증하여 유지합니다. Vault는 복구 share나 초기 root
토큰을 두 번째로 반환할 수 없습니다.

초기화에 성공했지만 SOPS 암호화에 실패하면 mode `0600`인 임시 파일에 평문 응답을
보존하고 경로만 출력합니다. 해당 파일을 즉시 보호하세요. 성공하면 임시 평문을
제거합니다.

`secrets/vault-recovery.yaml`은 현재 Vault 저장소에 연결된 생성 출력입니다.
파괴적인 reset 후에는 매번 암호화된 대체 파일을 커밋하세요. 새 Vault를 초기화하는 데
사용할 수 없으며 Raft 데이터가 손실되면 더 이상 유효하지 않습니다.

## 사용법

```bash
k initialize vault
```

## 전제 조건

- KMS Worker가 `https://kms.vault.platform.scg.sh`에 배포되어 있고 정상입니다.
- `secrets/vault.yaml`을 복호화할 수 있고 Worker 키 백업과 Transit 토큰이 있습니다.
- `secrets/bootstrap.yaml`에 Vault와 공유하는 Dex client secret이 있습니다.
- 로컬 age 키로 기존 복구 파일을 복호화할 수 있고, 대체 파일 암호화를 위해 SOPS에
  수신자가 하나 이상 구성되어 있습니다.
- Argo CD가 Vault, cert-manager, Gateway, `local-data`를 조정했습니다.
- Argo CD Application은 `main`에서 읽으므로 커밋된 Vault Application과 values가
  저장소의 `main` 브랜치에 있습니다.

실제 클러스터를 변경하는 작업입니다. 클러스터 리소스를 생성하며 새 Vault를 초기화할
수 있습니다. 기존 Vault를 다시 초기화하지는 않습니다.
