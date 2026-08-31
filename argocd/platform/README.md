한국어 | [English](README.en.md)

# 플랫폼 구성 요소

이 디렉터리는 애플리케이션을 지원하는 클러스터 서비스를 정의합니다.
활성 구성 요소는 각각 [`../kustomization.yaml`](../kustomization.yaml)로 조합되고
`platform` AppProject에 배정되는 Argo CD `Application`입니다.

## 구성 요소

| 디렉터리 | 용도 |
| --- | --- |
| [`argocd/`](argocd/) | Argo CD 차트, 네임스페이스 리소스, 공개 라우트 |
| [`gateway-api/`](gateway-api/) | upstream 표준 Gateway API 정의 |
| [`cilium/`](cilium/) | CNI, kube-proxy replacement, eBPF 및 network policy |
| [`envoy-gateway/`](envoy-gateway/) | Envoy Gateway controller 및 전용 CRD |
| [`cert-manager/`](cert-manager/) | ZeroSSL Cloudflare issuer 및 플랫폼 인증서 |
| [`external-dns-scg.sh/`](external-dns-scg.sh/) | `scg.sh` Gateway HTTPRoute용 Cloudflare 레코드 |
| [`external-secrets/`](external-secrets/) | 외부 값을 네임스페이스 범위 Kubernetes Secret으로 동기화 |
| [`gateway/`](gateway/) | Envoy 공개 Gateway, listener policy 및 `gateway-system` 네임스페이스 |
| [`local-path-provisioner/`](local-path-provisioner/) | Talos 사용자 저장소의 동적 노드 로컬 볼륨 |
| [`mysql/`](mysql/) | PXC 클러스터 리소스 및 네임스페이스 범위 Vault 연동 |
| [`percona-operator/`](percona-operator/) | `mysql`의 Percona XtraDB Cluster 리소스 조정 |
| [`reloader/`](reloader/) | 참조된 Secret이 변경될 때 관리형 워크로드 rolling restart |
| [`vault/`](vault/) | Raft 저장소와 Cloudflare Worker 자동 봉인 해제를 사용하는 Vault server |
| [`external-dns-scg.skku.ac.kr/`](external-dns-scg.skku.ac.kr/) | 비활성 RFC2136 참조 구성 |

일반적인 조사에서는 전체 controller 연결을 따라가세요.

| 증상 또는 작업 | 시작 위치 | 다음 확인 위치 |
| --- | --- | --- |
| 공개 라우트 | Gateway 및 HTTPRoute condition | cert-manager, 그다음 ExternalDNS |
| 관리형 시크릿 | Vault 경로 및 policy | External Secrets, 그다음 Reloader |
| 상태 저장 로컬 볼륨 | StorageClass 및 PersistentVolume | local path provisioner, 노드 경로, Talos 볼륨 |
| GitOps 조정 | 생성된 Application 또는 플랫폼 Application | AppProject 권한 및 루트 sync wave |

활성 구성 요소는 자동 sync, 정리, 자동 복구를 사용합니다. 루트는 다음 조정 순서를
사용합니다.

| Wave | 구성 요소 | 의존성 의도 |
| --- | --- | --- |
| 1 | Gateway API, Cilium, Envoy Gateway, External Secrets, local path provisioner | API, 네트워크, Gateway controller, 저장소 기반 |
| 2 | Gateway, cert-manager, Percona PXC Operator, Reloader | 공개 Gateway, 인증서 및 애플리케이션 지원 controller |
| 3 | Argo CD, ExternalDNS, MySQL 리소스, Vault | 외부 라우팅 및 상태 저장 서비스 |

wave는 child Application 조정을 순서대로 시작하며 다음 wave를 시작하기 전에 한 구성
요소가 완전히 정상화될 때까지 기다리지는 않습니다. 부트스트랩 자격 증명은 암호화된
값을 사용하여 `k install argocd`가 생성합니다. 플랫폼 values 파일에 토큰을 절대
넣지 마세요.

Vault는 기본값이 아닌 `local-data` class, `vault.platform.scg.sh`의 HTTPS,
`kms.vault.platform.scg.sh`의 Transit 호환 Worker를 사용합니다. 초기화, 복구,
관리형 시크릿 계약은 [Vault 구성 요소 README](vault/README.md)에 문서화되어 있습니다.

## 공개 라우팅

공개 Gateway는 다음 label이 지정된 네임스페이스의 라우트를 허용합니다.

```yaml
gateway.scg.sh/public: "true"
```

활성 ExternalDNS 인스턴스는 Gateway HTTPRoute를 감시하고 Cloudflare를 통해
`scg.sh` 레코드를 관리합니다.
테스팅과 프리뷰 listener는 ExternalDNS와 cert-manager가 제공하는 wildcard DNS
레코드와 인증서를 사용합니다. external로 표시된 프로덕션 도메인은 이 DNS 및 인증서
흐름에서 제외됩니다.

## 변경

각 구성 요소의 Application을 이곳에 유지하고
[`../kustomization.yaml`](../kustomization.yaml)에 포함하세요.
적합한 가장 좁은 AppProject 권한을 선택하고 병합 전에 sync wave, 네임스페이스,
자격 증명, 클러스터 범위 리소스를 검토하세요.

`external-dns-scg.skku.ac.kr/` 아래 파일은 `.example`로 끝나며 완전한 DNS 및 시크릿
구성이 승인될 때까지 비활성 참조 구성입니다.
