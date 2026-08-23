한국어 | [English](argocd.en.md)

# argocd

Argo CD를 부트스트랩하고 저장소의 GitOps 루트를 생성합니다.

## 동작

이 명령은 다음 작업을 수행합니다.

1. `argocd` 네임스페이스, GitHub OAuth 및 webhook Secret, Vault OIDC client
   Secret을 생성합니다.
1. 고정된 Argo CD 차트를 렌더링하고 Argo CD와 같은 server-side field manager로
   적용합니다.
1. 렌더링된 모든 차트 Job과 Argo CD deployment를 기다린 뒤 ApplicationSet
   controller를 새로 고칩니다.
1. cert-manager 및 ExternalDNS 네임스페이스와 각 Cloudflare Secret, ZeroSSL EAB
   Secret을 생성합니다.
1. [`argocd/root-application.yaml`](../../../argocd/root-application.yaml)을 적용합니다.
1. `argocd-initial-admin-secret`을 제거합니다.

시크릿은 암호화된 `secrets/bootstrap.yaml`에서 가져오며 values 파일에 커밋하지
않고 표준 입력으로 전달합니다. 이후 루트 Application이 Git에서 Argo CD 차트,
Cilium, Gateway API, 나머지 목표 상태를 조정합니다.

## 사용법

```bash
k install argocd
```

## 전제 조건

- `secrets/bootstrap.yaml`을 복호화할 수 있고
  `ARGOCD_GITHUB_OAUTH_CLIENT_SECRET`, `ARGOCD_GITHUB_WEBHOOK_SECRET`,
  `CLOUDFLARE_API_TOKEN`, `VAULT_OIDC_CLIENT_SECRET`,
  `ZEROSSL_EAB_HMAC_KEY`의 실제 값이 있습니다.
- Cilium이 설치되어 있고 클러스터에 연결할 수 있습니다.
- 고정된 Argo CD Helm 저장소에 접근할 수 있습니다.
- [`argocd/values.yaml`](../../../argocd/values.yaml)과
  [`argocd/root-application.yaml`](../../../argocd/root-application.yaml)이 있습니다.

확인 질문 없이 실제 클러스터를 변경하는 작업입니다. 부트스트랩 후 일반 업그레이드를
위해 이 명령을 다시 실행하지 말고 Git에서 목표 상태를 변경하세요.
