한국어 | [English](README.en.md)

# Argo CD 구성

이 디렉터리에는 GitOps 루트, 플랫폼 Application, ApplicationSet, 프로젝트, 공유
관리형 애플리케이션 차트가 있습니다.
Argo CD는 `main`을 추적하며 정리와 자동 복구를 활성화한 채 조정합니다.

## 부트스트랩

Kubernetes와 Cilium을 사용할 수 있게 되면 운영자가 다음을 실행합니다.

```bash
k install argocd
```

이 명령은 고정된 Argo CD 차트를 렌더링하고 적용하고, 암호화된 값에서 부트스트랩
Secret을 생성한 뒤 [`root-application.yaml`](root-application.yaml)을 적용합니다.
이후 루트 Application이 이 디렉터리를 조정하며 Argo CD 자체, Cilium, Gateway API,
나머지 플랫폼 목표 상태의 지속적인 소유권을 인계받습니다. 초기 admin Secret은
제거되며 [`values.yaml`](values.yaml)의 GitHub OAuth 구성을 통해 접근합니다.

`values.yaml`은 부트스트랩 렌더링과 Argo CD Application에서 함께 사용합니다.
OAuth client secret은 암호화된 부트스트랩 데이터에서 읽으며 이곳에 커밋하면 안
됩니다.

## 접근 및 새로 고침

일반 GitHub 팀에는 Argo CD 읽기 전용 접근 권한이 있습니다.
애플리케이션 변경은 Git에서 수행하며 controller의 자동 sync는 계속 활성화합니다.

GitHub push webhook은 `argocd.platform.scg.sh`의 다음 경로를 사용합니다.

- `/api/webhook`은 Argo CD API server를 새로 고칩니다.
- `/applicationset-webhook`은 ApplicationSet controller를 새로 고칩니다.

두 번째 경로는 내부에서 ApplicationSet webhook endpoint로 재작성됩니다.
같은 시크릿과 push event로 GitHub 저장소 webhook 두 개를 모두 생성하세요.
Webhook이 지연되거나 사용할 수 없을 때를 대비해 Git polling은 180초 간격으로 계속
활성화합니다. Webhook delivery는 `application/json`과 암호화된
`ARGOCD_GITHUB_WEBHOOK_SECRET` 값을 사용합니다.

## 디렉터리 구성

- [`application-sets/`](application-sets/)는 관리형, 프리뷰, 사용자 정의
  애플리케이션을 검색합니다.
- [`charts/`](charts/)에는 공유 관리형 애플리케이션 renderer가 있습니다.
- [`platform/`](platform/)은 클러스터 서비스용 Application을 정의합니다.
- [`projects/`](projects/)는 소스, 대상, 리소스 권한을 정의합니다.
- [`kustomization.yaml`](kustomization.yaml)은 루트 리소스를 조합합니다.
- [`root-application.yaml`](root-application.yaml)은 부트스트랩 중 적용됩니다.

## 변경 지침

애플리케이션 담당자는 일반적으로 [`../applications/`](../applications/)을 편집해야
합니다. 이곳의 변경은 여러 워크로드, 네임스페이스 또는 클러스터 전체 서비스에
영향을 줄 수 있습니다.
병합 전에 ApplicationSet 검색, 프로젝트 권한, sync wave, 시크릿, 클러스터 범위
리소스를 검토하세요.

Argo CD가 관리하는 리소스를 클러스터에서 편집하지 말고 Git에서 목표 상태를
변경하세요. 일반적인 Argo CD 구성과 차트 업그레이드에는 Git을 사용하세요.
GitOps를 사용할 수 없어서 부트스트랩 상태를 복구할 때만 `k install argocd`를 다시
실행하세요.
