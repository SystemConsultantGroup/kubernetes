한국어 | [English](README.en.md)

# 애플리케이션

이 디렉터리에는 SCG 플랫폼에 배포되는 워크로드가 있습니다.
애플리케이션 담당자는 일반적으로 이 파일들을 변경하고 풀 리퀘스트를 제출합니다.
`main`에 병합하면 선언된 상태를 Argo CD가 사용할 수 있게 됩니다.

애플리케이션 디렉터리에는 다음 레이아웃 중 하나를 선택하세요.

| 레이아웃 | 사용 시점 | 진입점 |
| --- | --- | --- |
| 관리형 | 공유 Deployment, Service, 라우팅, 시크릿 규칙으로 충분할 때 | `meta.yaml` 및 `instances/` |
| 사용자 정의 | 공유 차트가 제공하지 않는 Kubernetes 리소스가 필요할 때 | `kustomization.yaml` |

레이아웃을 섞거나 애플리케이션 파일에 자격 증명을 넣지 마세요. 워크로드를 표현할 수
없는 경우가 아니라면 관리형 레이아웃으로 시작하세요. 더 엄격한 검증과 일관된
프리뷰를 제공합니다.

## 관리형 애플리케이션

일반적인 워크플로는 다음과 같습니다.

1. `meta.yaml`에 런타임 동작을 한 번 정의합니다.
1. 각 워크로드의 변경 불가능한 프로덕션 잠금 파일을 추가합니다.
1. 선택적으로 테스팅 또는 풀 리퀘스트 프리뷰 잠금 파일을 추가합니다.
1. 메타데이터와 잠금 파일의 일관성이 유지되도록 변경을 함께 제출합니다.

관리형 애플리케이션의 구조는 다음과 같습니다.

```text
applications/example/
  meta.yaml
  instances/
    production.yaml
    testing.yaml
    preview/
      web/
        123.yaml
```

`meta.yaml`에는 워크로드 이름과 런타임 구성이 있지만 `source`나 `image`는 절대
포함하지 않습니다. 안정 인스턴스 파일에는 변경 불가능한 소스와 이미지 잠금만
정확히 포함합니다. 프로덕션은 필수이고 테스팅은 선택 사항입니다. 프리뷰의 식별자는
프리뷰 파일 경로에서 결정됩니다.

애플리케이션, 워크로드, 생성된 식별자 구성 요소에는 소문자 DNS 형식 이름을
사용합니다. 전체 Argo CD 식별자는 `-production`, `-testing` 또는
`-preview-<workload>-<pull-request>`를 포함하여 63자 이하여야 합니다. 내부
워크로드 리소스는 필요하면 안정적인 해시 접미사를 사용할 수 있지만 Application과
네임스페이스 식별자는 사용할 수 없습니다.

부트스트랩 후 애플리케이션 저장소는 공유
[애플리케이션 배포 워크플로](../.github/)를 통해 이 잠금 파일을 관리할 수 있습니다.
워크플로는 `main`, `testing` 또는 같은 저장소의 풀 리퀘스트에 대해 변경 불가능한
이미지를 게시한 뒤 해당 프로덕션, 테스팅 또는 프리뷰 잠금 파일을 이곳에 적용합니다.
풀 리퀘스트를 닫으면 해당 프리뷰 잠금 파일을 제거합니다.

### 최소 예시

저장소의 최소 공개 HTTP 예시는
[`example/`](example/)입니다.

`applications/example/meta.yaml`:

```yaml
fe:
  http:
    port: 8080
    domain: example.scg.sh
```

이 예시의 프로덕션, 테스팅, 프리뷰 잠금 파일은 모두 같은 변경 불가능한 소스 및
이미지 쌍을 사용합니다.
생성되는 식별자는 다음과 같습니다.

```text
example-production
example-testing
example-preview-fe-1
```

각 인스턴스는 `example-fe`라는 Deployment와 Service를 생성합니다.
Service는 포트 80에서 수신하고 컨테이너 포트 8080을 대상으로 합니다.
프로덕션 라우팅은 `example.scg.sh`를 사용하고, 테스팅과 프리뷰는 플랫폼이 생성한
호스트 이름을 사용합니다.
전체 이름 및 라우팅 규칙은 차트 README를 참조하세요.

### 전체 예시

`meta.yaml`은 여러 워크로드와 워크로드 간 라우팅을 구성할 수 있습니다.

```yaml
web:
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  env:
    - name: LOG_LEVEL
      value: info
    - name: PORT
      value: "8080"
  envFrom:
    - configMapRef:
        name: shop-config
  readinessProbe:
    httpGet:
      path: /ready
      port: http
    periodSeconds: 10
  http:
    port: 8080
    domain:
      name: shop.example.org
      external: false
    rules:
      - name: api
        matches:
          - path:
              type: PathPrefix
              value: /api
        backendRefs:
          - name: api
            port: 80
      - name: web
        backendRefs:
          - name: web
            port: 80

api:
  replicas: 2
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
  envFrom:
    - secretRef:
        name: shop-api-secrets
  readinessProbe:
    httpGet:
      path: /healthz
      port: http
  http:
    port: 9000
```

`api` 워크로드에는 도메인이 없으므로 Service는 있지만 공개 라우트는 없습니다.
`web` 규칙은 `/api`를 `api` Service로 보내고 그 밖의 모든 트래픽을 `web`
Service로 보냅니다.
백엔드 참조에는 워크로드 키를 사용하며 차트가 로컬 워크로드 참조를 생성된 Service
이름으로 확장합니다.

해당 프로덕션 인스턴스는 두 워크로드를 모두 잠가야 합니다.

```yaml
web:
  source:
    repository: https://github.com/example/shop-web.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

api:
  source:
    repository: https://github.com/example/shop-api.git
    revision: fedcba9876543210fedcba9876543210fedcba98
  image: registry.example.org/example/shop-api@sha256:fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210
```

각 소스 리비전은 소문자 40자리 전체 Git SHA여야 합니다.
각 이미지는 소문자 64자리 SHA-256 다이제스트로 고정된, 소문자로 된 정규화된 전체
OCI 참조여야 합니다.
소스와 이미지는 같은 빌드에서 나와야 합니다.

### 프리뷰 인스턴스

프리뷰 잠금 파일을 다음 위치에 두세요.

```text
applications/example/instances/preview/web/123.yaml
```

이 파일에는 선택한 워크로드의 잠금만 포함합니다.

```yaml
source:
  repository: https://github.com/example/shop-web.git
  revision: 0123456789abcdef0123456789abcdef01234567
image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

생성되는 프리뷰 식별자는 다음과 같습니다.

```text
<application>-preview-<workload>-<pull-request>
```

프리뷰 배포는 복제본 하나를 사용합니다. 프리뷰는 선택한 워크로드만 렌더링하며,
다른 로컬 워크로드에 대한 참조는 해당 테스팅 Service를 대상으로 합니다.

### CIDR 접근 필터링

워크로드별 `meta.yaml`에서 `http.allowCIDRs`를 선언하면 프로덕션으로 들어오는
요청이 나열된 CIDR(사무실 대역, 단일 IP)로만 허용됩니다. 앱 코드 변경은 필요
없습니다.

```yaml
manage:
  http:
    port: 9090
    domain: manage.shop.example.org
    allowCIDRs:
      - 115.145.150.0/24
```

선언하지 않은 워크로드(fe, be)는 제한 없이 접근됩니다. 테스팅과 프리뷰
인스턴스는 선언과 무관하게 항상 플랫폼 CIDR 목록으로만 접근할 수 있습니다.
상세 규칙은 [차트 README](../argocd/charts/application/)를 참조하세요.

### 관리형 시크릿 값

관리형 워크로드는 해당 경로가 있으면 플랫폼의 Vault 연동에서 환경 값을 자동으로
받습니다. 애플리케이션 메타데이터에는 Vault 구성이나 평문 값을 절대 넣지 않습니다.
프로덕션과 테스팅은 각자의 경로를 사용합니다. 프리뷰는 테스팅 값을 상속한 뒤 선택한
워크로드의 공유 프리뷰 재정의를 적용합니다.

Vault 경로가 없어도 허용되므로 애플리케이션은 시작할 때 필수 값을 검증해야 합니다.
테스팅 자격 증명은 프리뷰 코드에서 사용해도 안전해야 합니다. 시크릿 값을 담당하는
구성원은 [Vault 애플리케이션 값 워크플로](../argocd/platform/vault/README.md#%EC%95%A0%ED%94%8C%EB%A6%AC%EC%BC%80%EC%9D%B4%EC%85%98-%EA%B0%92-%EA%B4%80%EB%A6%AC)를
따라야 합니다.

## 사용자 정의 Kustomize 애플리케이션

사용자 정의 애플리케이션은 루트에 표준 Kustomize 진입점이 있습니다.

```text
applications/example/
  kustomization.yaml
  resources.yaml
```

생성되는 Argo CD Application과 네임스페이스의 이름은 다음과 같습니다.

```text
<application>
```

`kustomize.yaml`이 아니라 `kustomization.yaml`을 사용하세요. `meta.yaml`이나
`instances/` 트리를 추가하지 마세요. 사용자 정의 애플리케이션에는 관리형 테스팅
또는 프리뷰 인스턴스가 제공되지 않으므로 원하는 모든 리소스를 Kustomization에
정의하세요.

명시적인 네임스페이스가 있는 리소스는 애플리케이션에 생성된 네임스페이스만 대상으로
할 수 있고, 선언된 Namespace는 애플리케이션 이름을 사용해야 합니다. 애플리케이션
개발자에게 클러스터 또는 `k` 자격 증명이 없으므로 병합된 Git 변경에 대한 플랫폼
검토가 권한 부여 경계입니다.

## 검증 및 상세 스키마

플랫폼 엔지니어는 검토 중에 저장소 검사를 실행하여 관리형 또는 사용자 정의
레이아웃, 필수 프로덕션 잠금, 워크로드 일관성, 프리뷰 식별자, 생성된 이름 길이 제한,
로컬 렌더링을 검증합니다. 애플리케이션 개발자에게는 플랫폼 전용 `k` 명령에 대한
접근 권한이 필요하지 않습니다.

검토를 요청하기 전에 다음 사항을 확인하세요.

- 애플리케이션 디렉터리는 한 가지 레이아웃만 사용합니다.
- 모든 안정 잠금 파일에는 `meta.yaml`의 워크로드가 정확히 포함됩니다.
- 모든 잠금 파일은 같은 빌드의 전체 커밋 SHA와 다이제스트 고정 이미지를 사용합니다.
- 프리뷰 워크로드 및 풀 리퀘스트 식별자가 파일 경로와 일치합니다.
- 도메인, 라우트, 참조된 Service가 의도한 대로입니다.
- 평문 자격 증명이나 로컬 구성 파일이 포함되어 있지 않습니다.

공유 차트는 생성된 엄격한 JSON 스키마로 실제 워크로드 구성을 검증합니다.
Kubernetes 네이티브 리소스, 환경 소스, readiness probe, Gateway API HTTP 라우트
규칙을 포함하여 허용되는 필드는
[`../argocd/charts/application/README.md`](../argocd/charts/application/README.md)에
문서화되어 있습니다.

이 파일을 Argo CD Application으로 변환하는 ApplicationSet은
[`../argocd/application-sets/README.md`](../argocd/application-sets/README.md)에
설명되어 있습니다.
