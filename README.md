# GitOps

SCG Kubernetes 클러스터의 플랫폼을 Argo CD로 관리합니다.

## 전제

`../init.sh`가 다음 항목을 bootstrap합니다.

- Gateway API CRD
- Cilium (`gatewayAPI.hostNetwork.enabled=true`)
- Argo CD
- cert-manager DNS 자격증명
- `clusters/scg`를 바라보는 Root Application

Cilium과 Argo CD 자체는 이 저장소에서 다시 설치하지 않습니다.

## 구조

```text
clusters/scg/
├── kustomization.yaml
├── project.yaml
└── applicationsets/platform.yaml

platform/
├── argocd/
├── gateway/
├── cert-manager/
└── argocd-image-updater/
```

`platform/*/meta.yaml`을 ApplicationSet이 읽어 Helm 또는 Kustomize Application을 생성합니다.

## 현재 설정

| 항목 | 값 |
| --- | --- |
| Cluster / Argo CD Project | `scg` |
| Git repository | `https://github.com/SystemConsultantGroup/gitops.git` |
| GatewayClass | `cilium` |
| Gateway address | `115.145.134.232` |
| Argo CD | `https://argocd.infra.scg.sh` |
| Argo CD login | GitHub `SystemConsultantGroup/active` 구성원만 허용 |
| Public domains | `*.scg.sh`, `*.scg.skku.ac.kr` |
| ACME email | `scg@scg.skku.ac.kr` |
| `scg.sh` DNS-01 | Cloudflare API Token |
| `scg.skku.ac.kr` DNS-01 | RFC2136 `115.145.172.17:53`, `cert-manager-key`, `HMACSHA256` |

DNS zone 이전 전에는 인증서를 발급하지 않습니다. 이전 후 `platform/cert-manager/resources/kustomization.yaml`에 `certificates.yaml`을 추가합니다.

## Bootstrap 설정과 자격증명

클러스터 주소와 GitHub 로그인 설정은 `../init.sh` 상단에서 수정합니다.

```bash
MAIN_IP="115.145.134.232"
ARGOCD_URL="https://argocd.infra.scg.sh"
ARGOCD_GITHUB_ORG="SystemConsultantGroup"
ARGOCD_GITHUB_TEAM_SLUG="active"
ARGOCD_GITHUB_CLIENT_ID="..."
```

클러스터 생성 전에 bootstrap 환경에 다음 Secret을 주입합니다.

- `CLOUDFLARE_API_TOKEN`: `Zone:DNS:Edit`, `Zone:Zone:Read`, `scg.sh`로 제한
- `RFC2136_TSIG_SECRET`: TSIG shared key의 Base64 문자열
- `ARGOCD_GITHUB_CLIENT_SECRET`: GitHub OAuth App Client Secret

로컬 실행 시 값이 shell history에 남지 않도록 입력합니다.

```bash
read -rsp 'Cloudflare API token: ' CLOUDFLARE_API_TOKEN; echo
read -rsp 'RFC2136 TSIG secret: ' RFC2136_TSIG_SECRET; echo
read -rsp 'GitHub OAuth client secret: ' ARGOCD_GITHUB_CLIENT_SECRET; echo
export CLOUDFLARE_API_TOKEN RFC2136_TSIG_SECRET ARGOCD_GITHUB_CLIENT_SECRET

(cd .. && ./init.sh)

unset CLOUDFLARE_API_TOKEN RFC2136_TSIG_SECRET ARGOCD_GITHUB_CLIENT_SECRET
```

CI에서는 같은 환경변수를 CI Secret에서 주입합니다. `init.sh`는 값을 Git에 저장하지 않고 Kubernetes Secret으로 생성하며, GitHub `active` Team 구성원만 Argo CD에 로그인하고 `admin` 역할을 받도록 설정합니다.

## 배포

GitOps 파일을 `main`에 push한 뒤 bootstrap 스크립트를 실행합니다. Root Application까지 자동으로 적용됩니다.

`argocd.infra.scg.sh` DNS 레코드는 노드 IP `115.145.134.232`를 가리켜야 합니다.

Argo CD가 다음 Application을 생성합니다.

```text
scg-argocd
scg-cert-manager
scg-gateway
scg-argocd-image-updater
```

외부 Route를 연결할 namespace에는 다음 label이 필요합니다.

```yaml
gateway.scg.sh/public: 'true'
```

애플리케이션 배포(`apps/`)와 ImageUpdater CR은 실제 앱을 추가할 때 구성합니다.
