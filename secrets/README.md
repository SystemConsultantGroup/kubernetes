한국어 | [English](README.en.md)

# 암호화된 시크릿

이 디렉터리에는 클러스터 부트스트랩과 운영에 필요한 암호화된 값이 있습니다.
SOPS는 [`state.yaml`](state.yaml)의 공개 age 수신자 맵과 생성된 루트
[`.sops.yaml`](../.sops.yaml)을 사용합니다.

| 작업 | 명령 |
| --- | --- |
| 로컬 수신자 생성 또는 확인 | `k secrets recipients me` |
| 접근 권한 및 암호화 검증 | `k secrets check` |
| 암호화된 값 편집 | `k secrets edit <name>` |
| 접근 권한 부여 | `k secrets recipients add <name> <age1...>` |
| 접근 권한 취소 | `k secrets recipients remove <name>` |

접근 권한을 부여하거나 취소하면 암호화된 모든 시크릿의 키를 다시 설정하며 명시적
승인이 필요합니다. 자세한 명령 도움말은 `k <command> --help`에서 확인할 수 있습니다.

## 파일

| 파일 | 내용 |
| --- | --- |
| `state.yaml` | 공개 수신자 별칭 및 age 수신자이며 시크릿 값은 없음 |
| `bootstrap.yaml` | 암호화된 Argo CD OAuth 및 webhook, Cloudflare, ZeroSSL 부트스트랩 값 |
| `talos.yaml` | 암호화된 Talos 클러스터 시크릿 |
| `vault.yaml` | 암호화된 Vault Transit seal 토큰과 Worker 키의 복구용 사본 |
| `vault-recovery.yaml` | 현재 Vault 데이터용으로 생성 및 암호화된 복구 share이며 운영자 접근을 확인한 뒤 임시 초기 root 토큰은 제거됨 |

`state.yaml`을 제외한 모든 파일은 Git에서 암호화된 상태로 유지하세요.
`.sops.yaml`을 직접 편집하지 마세요. 수신자 명령이 이 파일을 다시 생성합니다.

## 접근 권한 부여

로컬 age 키를 생성하거나 확인하고 수신자를 출력하세요.

```bash
k secrets recipients me
```

수신자를 기존 운영자에게 보내세요.
요청을 확인한 운영자는 별칭을 추가하고 암호화된 모든 파일의 키를 다시 설정할 수
있습니다.

```bash
k secrets recipients add <name> <age1...>
```

접근 권한을 부여한 뒤 키, 수신자 맵, SOPS 구성, 암호화된 파일을 검증하세요.

```bash
k secrets check
```

기본 키 경로는 `${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`입니다.
다른 경로를 사용하려면 `SOPS_AGE_KEY_FILE`을 설정하세요.

## 값 편집

`.sops.yaml`의 동기화가 유지되도록 래퍼를 사용하세요.

```bash
k secrets edit bootstrap
k secrets edit talos
k secrets edit vault
```

`k install`을 완료하려면 먼저 `bootstrap.yaml`에
`ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `ARGOCD_GITHUB_WEBHOOK_SECRET`,
`CLOUDFLARE_API_TOKEN`, `VAULT_OIDC_CLIENT_SECRET`,
`ZEROSSL_EAB_HMAC_KEY`의 실제 값이 있어야 합니다. `k initialize vault`를
실행하기 전에 `vault.yaml`에는 `VAULT_TRANSIT_SEAL_TOKEN`과
`VAULT_TRANSIT_SEAL_KEY_V1`이 있어야 합니다.
Cloudflare 토큰은 관련 zone을 읽고 DNS 레코드를 편집할 수 있어야 합니다.

복호화된 값을 출력하거나 평문을 커밋하거나 애플리케이션 메타데이터, 플랫폼 값,
패치, 문서에 자격 증명을 넣지 마세요.
수신자 변경은 암호화된 모든 시크릿에 대한 접근 권한을 부여하거나 취소하므로 반드시
명시적으로 승인해야 합니다.
