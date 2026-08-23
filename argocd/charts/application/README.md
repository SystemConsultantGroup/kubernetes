한국어 | [English](README.en.md)

# Application 차트

이 차트는 관리형 SCG 애플리케이션 인스턴스 하나를 렌더링합니다.
ApplicationSet은 세 입력을 결합합니다.

1. `applications/<application>/meta.yaml`의 애플리케이션 메타데이터
1. 인스턴스 파일의 변경 불가능한 소스 및 이미지 잠금
1. 애플리케이션과 인스턴스 유형을 설명하는 내부 `_context`

이 차트는 플랫폼 코드입니다. 변경은 모든 관리형 애플리케이션에 영향을 줄 수
있습니다. 애플리케이션 담당자는
[애플리케이션 워크플로](../../../applications/README.md)로 시작하고 이 페이지를
필드 및 렌더링 참조로 사용해야 합니다.

## 빠른 이동

- [Values 조합](#values-%EC%A1%B0%ED%95%A9)
- [이름 모델](#%EC%9D%B4%EB%A6%84-%EB%AA%A8%EB%8D%B8)
- [워크로드 필드](#%EC%9B%8C%ED%81%AC%EB%A1%9C%EB%93%9C-%ED%95%84%EB%93%9C)
- [관리형 Vault 환경](#%EA%B4%80%EB%A6%AC%ED%98%95-vault-%ED%99%98%EA%B2%BD)
- [HTTP Service 및 라우팅](#http)
- [변경 불가능한 잠금](#%EB%B3%80%EA%B2%BD-%EB%B6%88%EA%B0%80%EB%8A%A5%ED%95%9C-%EC%9E%A0%EA%B8%88)
- [인스턴스 동작](#%EC%9D%B8%EC%8A%A4%ED%84%B4%EC%8A%A4-%EC%9C%A0%ED%98%95%EB%B3%84-%EB%A0%8C%EB%8D%94%EB%A7%81)
- [로컬 렌더링](#%EB%A1%9C%EC%BB%AC-%EB%A0%8C%EB%8D%94%EB%A7%81)

## Values 조합

안정적인 프로덕션 또는 테스팅 렌더링은 개념적으로 다음과 같습니다.

```yaml
_context:
  application: shop
  instance:
    type: production

web:
  replicas: 2
  http:
    port: 8080
  source:
    repository: https://github.com/example/shop-web.git
    revision: 0123456789abcdef0123456789abcdef01234567
  image: registry.example.org/example/shop-web@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

Helm은 스키마 검증 전에 메타데이터와 인스턴스 파일을 병합합니다.
저장소 검사는 소스 파일 경계를 강제합니다. 런타임 구성은 `meta.yaml`에 두고 각
인스턴스 잠금 파일에는 정확히 `source`와 `image`만 넣습니다. 애플리케이션 담당자는
메타데이터에 잠금을 넣거나 인스턴스 파일에 런타임 필드를 넣으면 안 됩니다.

## 이름 모델

ApplicationSet 식별자는 애플리케이션 이름으로 시작합니다.

| 인스턴스 | Application, release, 네임스페이스 |
| --- | --- |
| 프로덕션 | `<application>-production` |
| 테스팅 | `<application>-testing` |
| 프리뷰 | `<application>-preview-<workload>-<pull-request>` |
| 사용자 정의 Kustomize | `<application>` |

관리형 네임스페이스 안에서 워크로드 리소스는 다음 형식입니다.

```text
<application>-<workload>
```

예를 들어 `shop`에 `web` 워크로드가 있으면 다음을 생성합니다.

```text
Deployment: shop-web
Service:    shop-web
Secret:     shop-web-environment
```

Secret은 중앙에서 관리하는 Vault 연동이 활성화되어 있고 해당 Vault 경로에 데이터가
있는 경우에만 존재합니다.

차트가 제어하는 이름이 Kubernetes 또는 DNS label 제한을 초과하면 읽을 수 있는
접두사를 보존하고 전체 이름의 안정적인 해시를 덧붙입니다. ApplicationSet 이름과
네임스페이스에는 별도의 `app-` 접두사를 추가하지 않습니다. 저장소 검사가 조정 전에
결합된 길이를 강제합니다.

## 스키마 규칙

생성된 `values.schema.json`은 엄격합니다.

- 알 수 없는 최상위 키를 거부합니다.
- 알 수 없는 워크로드 필드를 거부합니다.
- 중첩된 Kubernetes 및 Gateway API 객체의 알 수 없는 필드를 거부합니다.
- 워크로드 이름은 소문자 DNS 호환 이름이어야 합니다.
- 차트에는 워크로드가 하나 이상 필요하고 렌더링하는 모든 워크로드에 소스 및 이미지
  잠금이 필요합니다.

JSON 스키마는 [`values.schema.source.json`](values.schema.source.json), Kubernetes
정의, Gateway API 정의에서 생성됩니다.
고정된 소스 버전은 `state.yaml`에 있습니다.

## 워크로드 이름

최상위 워크로드 키는 각각 1자 이상 63자 이하여야 하며 다음과 일치해야 합니다.

```text
^[a-z0-9](?:[-a-z0-9]*[a-z0-9])?$
```

이름에는 소문자, 숫자, 하이픈을 사용할 수 있습니다.
소문자 또는 숫자로 시작하고 끝나야 합니다.
이 이름은 메타데이터, label, backend reference, 생성되는 리소스 이름에서 워크로드
식별자로 사용됩니다.

## 워크로드 필드

워크로드에는 다음 필드를 사용할 수 있습니다.

| 필드 | 타입 | 동작 |
| --- | --- | --- |
| `replicas` | 최솟값 `1`인 정수 | 안정 인스턴스의 복제본 수이며 기본값은 `1`, 프리뷰에서는 `1`로 강제 |
| `resources` | Kubernetes `ResourceRequirements` | 컨테이너에 전달 |
| `env` | Kubernetes `EnvVar` 목록 | 컨테이너에 전달 |
| `envFrom` | Kubernetes `EnvFromSource` 목록 | 컨테이너에 전달 |
| `readinessProbe` | Kubernetes `Probe` | readiness probe로 렌더링 |
| `http` | SCG HTTP 구성 | 컨테이너 포트, Service, 선택적 라우팅 추가 |
| `source` | 변경 불가능한 소스 잠금 | 렌더링되는 모든 워크로드에 필수 |
| `image` | 변경 불가능한 이미지 잠금 | 렌더링되는 모든 워크로드에 필수 |

차트는 컨테이너 명령, 임의 포트, liveness probe, startup probe, 볼륨, volume mount,
ServiceAccount, 임의의 Pod 필드를 제공하지 않습니다.

## `replicas`

```yaml
replicas: 3
```

값은 `1` 이상의 정수여야 합니다.
프로덕션 및 테스팅 Deployment는 이 값을 사용합니다.
프리뷰 Deployment는 항상 복제본 하나를 사용합니다.

## `resources`

`resources`는 Kubernetes `ResourceRequirements`를 따릅니다.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

지원하는 필드는 다음과 같습니다.

- `requests`: 리소스 이름과 quantity 문자열의 맵
- `limits`: 리소스 이름과 quantity 문자열의 맵
- `claims`: resource claim 목록

resource claim에는 다음 항목이 있습니다.

- `name`: 필수 문자열
- `request`: 선택 문자열

스키마는 임의의 리소스 이름 키와 quantity 문자열을 허용하며 리소스별 검증은
Kubernetes가 수행합니다.

## `env`

```yaml
env:
  - name: LOG_LEVEL
    value: info
  - name: PORT
    value: "8080"
```

각 항목에는 `name`이 필요하며 `value` 또는 `valueFrom`을 포함할 수 있습니다.

`valueFrom`은 다음을 지원합니다.

- `configMapKeyRef`: `key`는 필수이고 `name`과 `optional`은 선택 사항
- `secretKeyRef`: `key`는 필수이고 `name`과 `optional`은 선택 사항
- `fieldRef`: `fieldPath`는 필수이고 `apiVersion`은 선택 사항
- `resourceFieldRef`: `resource`는 필수이고 `containerName`과 `divisor`는 선택 사항
- `fileKeyRef`: `volumeName`, `path`, `key`는 필수이고 `optional`은 선택 사항

예시:

```yaml
env:
  - name: LOG_LEVEL
    valueFrom:
      configMapKeyRef:
        name: shop-config
        key: LOG_LEVEL
  - name: API_TOKEN
    valueFrom:
      secretKeyRef:
        name: shop-secrets
        key: API_TOKEN
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
```

환경 값은 문자열입니다.
YAML에서 숫자나 boolean으로 해석될 수 있는 값은 따옴표로 감싸세요.

차트는 볼륨을 생성하지 않으므로 `fileKeyRef`는 애플리케이션 메타데이터만으로 생성한
볼륨을 참조할 수 없습니다.

## `envFrom`

```yaml
envFrom:
  - configMapRef:
      name: shop-config
  - secretRef:
      name: shop-secrets
    prefix: SHOP_
```

각 항목에는 다음을 사용할 수 있습니다.

- `prefix`: 선택 문자열
- 선택적인 `name` 및 `optional`이 있는 `configMapRef`
- 선택적인 `name` 및 `optional`이 있는 `secretRef`

값은 컨테이너의 Kubernetes `envFrom` 필드에 직접 전달됩니다. 관리형 Vault 연동이
활성화되면 선택적인 생성 Secret 소스를 먼저 렌더링하고 이 소스들을 그다음에
배치합니다.

## 관리형 Vault 환경

관리형 Vault 연동은 내부 플랫폼 동작이며 `meta.yaml`에 워크로드 필드가 없습니다.
중앙에서 활성화하면 렌더링되는 모든 워크로드에 다음 항목이 생깁니다.

- 생성된 ExternalSecret
- `<application>-<workload>-environment`에 대한 선택적인 `envFrom` 참조
- 공유 Vault 애플리케이션 role을 사용하는 네임스페이스 범위 SecretStore
- Secret 변경을 위한 자동 rollout annotation

안정 인스턴스는 논리적인 KV v2 경로 하나를 추출합니다.

```text
applications/<application>/<instance-type>/<workload>
```

프리뷰 인스턴스는 테스팅과 프리뷰 경로를 순서대로 병합합니다.

```text
applications/<application>/testing/<workload>
applications/<application>/preview/<workload>
```

Vault 키는 그대로 환경 변수 이름이 됩니다. `DATABASE_URL` 같은 이식 가능한 이름을
사용하세요. Vault 경로가 없으면 Kubernetes Secret도 없으며 선택적 환경 소스는
변수를 제공하지 않습니다. 값이 필요한 애플리케이션은 시작할 때 이를 검증해야 합니다.

External Secrets는 15초마다 polling하며 생성된 Kubernetes Secret을 소유합니다.
Vault 경로를 생성, 변경, 삭제하면 해당 Secret도 생성, 갱신, 삭제되고 Reloader가
Deployment를 rolling restart합니다. 명시적인 `env` 값은 모든 `envFrom` 소스보다
우선합니다. 애플리케이션이 제공한 `envFrom` 항목은 생성된 Vault 소스 뒤에 오므로
해당 키를 재정의할 수 있습니다.

프리뷰 워크로드는 공유 프리뷰 재정의 전에 테스팅 경로를 읽을 수 있습니다. 따라서
테스팅 자격 증명은 격리되어 있어야 하며 검토되지 않은 프리뷰 코드에서 사용해도
안전해야 합니다. 프리뷰 값은 워크로드 단위로 공유되며 풀 리퀘스트 번호별로 격리되지
않습니다.

ApplicationSet은 Vault 저장소, TLS, 초기화, 공유 애플리케이션 role이 준비된 뒤 이
연동을 중앙에서 활성화합니다. 설계와 활성화 절차는
[Vault 구성 요소 README](../../platform/vault/README.md)에 있습니다.

## `readinessProbe`

`readinessProbe`는 컨테이너에 렌더링되는 Kubernetes `Probe`입니다.
차트는 다음 timing 필드를 지원합니다.

- `initialDelaySeconds`
- `periodSeconds`
- `timeoutSeconds`
- `successThreshold`
- `failureThreshold`
- `terminationGracePeriodSeconds`

지원하는 handler는 `exec`, `grpc`, `httpGet`, `tcpSocket`입니다.

### HTTP probe

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: http
  periodSeconds: 10
```

`httpGet`은 다음을 지원합니다.

- `host`: 선택 문자열
- `path`: 선택 문자열
- `port`: 필수 정수 또는 named port 문자열
- `scheme`: 선택 문자열
- `httpHeaders`: 필수 `name` 및 `value` 쌍의 선택 목록

생성된 HTTP 컨테이너 포트의 이름은 `http`이므로 probe에서 `port: http`을 사용할 수
있습니다.

### TCP probe

```yaml
readinessProbe:
  tcpSocket:
    port: 8080
```

`tcpSocket`은 선택적인 `host`와 필수 정수 또는 named `port`를 지원합니다.

### Exec probe

```yaml
readinessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - test -f /tmp/ready
```

`command`는 문자열 목록입니다.

### gRPC probe

```yaml
readinessProbe:
  grpc:
    port: 9090
    service: health
```

`grpc.port`는 필수입니다. `service`는 선택 사항입니다.

차트는 liveness 또는 startup probe를 제공하지 않습니다.
Kubernetes가 일반적인 기본값과 의미 검증을 probe에 적용합니다.

## `http`

```yaml
http:
  port: 8080
```

`http.port`는 필수이며 `1`부터 `65535`까지의 정수여야 합니다.

`http`를 추가하면 다음이 생성됩니다.

- 구성된 컨테이너 포트를 사용하는 `http`라는 컨테이너 포트
- `<application>-<workload>`라는 ClusterIP Service
- 이름이 `http`인 포트를 대상으로 하는 Service 포트 `80`
- TCP protocol
- `appProtocol: http`

`http`가 없는 워크로드에는 Service나 컨테이너 포트가 생기지 않습니다.

## `http.domain`

domain은 다음 중 하나입니다.

- 호스트 이름 문자열 하나
- `{name, external}` 객체 하나
- 두 형식 중 하나로 구성된 비어 있지 않고 고유한 목록

호스트 이름은 1자 이상 253자 이하여야 하고 소문자 DNS label을 사용해야 하며
wildcard, 밑줄, 대문자, 마지막 점을 포함할 수 없습니다.
각 label은 63자 이하여야 합니다.

문자열 형식:

```yaml
domain: shop.example.org
```

객체 형식:

```yaml
domain:
  name: shop.example.org
  external: false
```

객체에는 `name`과 `external`이 모두 필요하며 추가 필드는 거부됩니다.

목록 형식:

```yaml
domain:
  - shop.example.org
  - name: legacy.example.org
    external: true
```

### 프로덕션 도메인

프로덕션은 domain마다 ListenerSet과 HTTPRoute를 하나씩 생성합니다.

문자열 domain은 `external: false`로 취급합니다.

- listener protocol: HTTPS
- listener port: `443`
- cert-manager Certificate 생성
- 라우트에 ExternalDNS 제외 표시 없음

차트는 각 워크로드 및 호스트 이름에 대해 `sha256(hostname)`의 첫 여덟 문자를
접미사로 사용합니다.

```text
<application>-<workload>-<sha256-hostname-prefix>
```

결과가 길면 읽을 수 있는 접두사를 보존하고 안정적인 해시를 덧붙입니다. `-tls`
파생 이름도 63자 제한 안에 있도록 기본 이름은 59자로 제한됩니다. ListenerSet과
HTTPRoute가 해당 이름을 사용합니다.
external이 아닌 domain은 이름 끝에 `-tls`를 붙인 Certificate 및 TLS Secret도
생성합니다.

external domain은 다음을 사용합니다.

- listener protocol: HTTP
- listener port: `80`
- Certificate 없음
- ExternalDNS 제외 annotation

DNS와 TLS 종료를 플랫폼 외부에서 관리할 때 `external: true`를 사용하세요.

### 테스팅 및 프리뷰 도메인

테스팅 및 프리뷰 인스턴스는 플랫폼의 wildcard DNS 레코드와 wildcard HTTPS
listener를 사용합니다. 라우트는 Gateway matching을 위해 인스턴스별 호스트 이름을
유지하지만 ExternalDNS는 플랫폼 wildcard만 게시합니다.

```text
Testing route: <application>.testing.scg.sh
Testing DNS:   *.testing.scg.sh
Preview route: <application>-<workload>-<pull-request>.preview.scg.sh
Preview DNS:   *.preview.scg.sh
```

인스턴스별 Certificate는 생성되지 않습니다. `external` 값은 테스팅 또는 프리뷰
listener 동작을 변경하지 않습니다.

## `http.rules`

`rules`는 Gateway API `HTTPRouteRule` 객체로 구성된 선택적인 비어 있지 않은
목록입니다. `rules`가 있으면 `domain`이 필수입니다.

```yaml
http:
  port: 8080
  domain: shop.example.org
  rules:
    - name: api
      matches:
        - path:
            type: PathPrefix
            value: /api
      backendRefs:
        - name: api
          port: 80
```

규칙에는 다음을 사용할 수 있습니다.

- `name`
- `matches`
- `filters`
- `backendRefs`
- `timeouts`

### 규칙 이름

`name`은 선택 사항이며 1자 이상 253자 이하의 소문자 DNS 형식 이름이어야 합니다.
생략하면 차트가 다음 형식으로 생성합니다.

```text
<application>-<workload>-<rule-number>
```

예시:

```text
shop-web-1
```

### Match

`matches`에는 항목을 최대 64개까지 넣을 수 있습니다.
생략하면 Gateway API가 `/`의 catch-all path prefix match를 기본값으로 사용합니다.

각 match에는 다음을 사용할 수 있습니다.

- `path`
- `headers`
- `queryParams`
- `method`

`path.type`은 `Exact`, `PathPrefix`, `RegularExpression` 중 하나입니다.
기본값은 값 `/`의 `PathPrefix`입니다.

header와 query parameter에는 필수 `name` 및 `value` 필드가 있습니다.
type은 `Exact` 또는 `RegularExpression`이며 기본값은 `Exact`입니다.
각 목록에는 항목을 최대 16개까지 넣을 수 있습니다.

`method`는 다음을 지원합니다.

```text
GET, HEAD, POST, PUT, DELETE, CONNECT, OPTIONS, TRACE, PATCH
```

`Exact` 및 `PathPrefix` 경로에 대해 Gateway API는 경로가 절대 경로이고 잘못된 탐색
또는 인코딩 패턴이 없는지 검증합니다.

### Backend reference

`backendRefs`에는 항목을 최대 16개까지 넣을 수 있습니다.

각 backend reference는 다음을 지원합니다.

- `name`: 필수 문자열
- `group`: 선택 사항이며 기본값은 빈 group
- `kind`: 선택 사항이며 기본값은 `Service`
- `namespace`: 선택 네임스페이스
- `port`: `1`부터 `65535`까지의 선택 정수
- `weight`: `0`부터 `1,000,000`까지의 선택 정수이며 기본값은 `1`
- `filters`: 선택 Gateway API backend filter

애플리케이션 로컬 Service 참조에는 워크로드 키를 사용합니다.

```yaml
backendRefs:
  - name: api
```

차트는 이를 생성된 Service 이름으로 변환합니다.

```text
<application>-api
```

로컬 Service 포트의 기본값도 `80`으로 설정합니다.
명시적 네임스페이스, 비어 있지 않은 group, `Service`가 아닌 kind가 있는 참조는
변경 없이 전달됩니다.

`backendRefs`가 생략되어 있고 redirect 전용 규칙이 아니면 차트는 소유 워크로드의
Service 포트 `80`에 대한 참조를 생성합니다.

### Filter

규칙에는 filter를 최대 16개까지 넣을 수 있습니다.
각 filter에는 `type`이 필요하며 다음 중 하나를 지원합니다.

- `RequestHeaderModifier`
- `ResponseHeaderModifier`
- `RequestMirror`
- `RequestRedirect`
- `URLRewrite`
- `ExtensionRef`
- `CORS`

request 및 response header modifier는 `add`, `set`, `remove`를 지원합니다.
`add`와 `set`에는 `{name, value}` 항목을 최대 16개까지 넣을 수 있고 `remove`에는
header 이름을 최대 16개까지 넣을 수 있습니다.

request mirror에는 `backendRef`와 다음 중 하나가 필요합니다.

- `0`부터 `100`까지의 `percent`
- 0 이상의 `numerator`와 양수 `denominator`가 있는 `fraction`

fraction denominator의 기본값은 `100`이며 numerator는 이를 초과할 수 없습니다.
percent와 fraction을 함께 사용할 수 없습니다.

request redirect는 다음을 지원합니다.

- `hostname`
- `port`
- `http` 또는 `https`인 `scheme`
- `301`, `302`, `303`, `307`, `308` 중 하나인 `statusCode`이며 기본값은 `302`
- `ReplaceFullPath` 또는 `ReplacePrefixMatch`를 사용하는 `path` 교체

URL rewrite는 `hostname`과 같은 path 교체 형식을 지원합니다.

extension reference에는 `group`, `kind`, `name`이 필요합니다.

CORS는 다음을 지원합니다.

- `allowCredentials`
- 최대 64개의 `allowHeaders`
- 최대 9개의 `allowMethods`
- 최대 64개의 `allowOrigins`
- 최대 64개의 `exposeHeaders`
- 기본값이 `5`인 `maxAge`

관련 CORS 목록에서 wildcard 값은 다른 값과 함께 사용할 수 없습니다.
filter type은 반복할 수 없으며 `RequestRedirect`와 `URLRewrite`를 함께 사용할 수
없습니다.

`backendRefs` 없이 `RequestRedirect`가 있는 규칙은 redirect 전용으로 유지됩니다.
차트는 기본 Service backend를 추가하지 않습니다.

### Timeout

```yaml
timeouts:
  request: 30s
  backendRequest: 25s
```

지원하는 필드는 `request`와 `backendRequest`입니다.
값은 `10s`, `1m`, `1m30s` 같은 Gateway API duration 구문을 사용합니다.
둘 다 제공할 때 request timeout이 0인 경우가 아니라면 `backendRequest`가 `request`를
초과할 수 없습니다.

## 변경 불가능한 잠금

### `source`

```yaml
source:
  repository: https://github.com/example/shop.git
  revision: 0123456789abcdef0123456789abcdef01234567
```

`source`에는 정확히 `repository`와 `revision`이 필요합니다. `meta.yaml`이 아니라
인스턴스 잠금 파일에 둡니다.

저장소는 `.git`으로 끝나는 HTTPS URL이어야 하며 자격 증명, query parameter,
fragment를 포함할 수 없습니다.
리비전은 소문자 40자리 전체 16진수 Git SHA여야 합니다.

### `image`

```yaml
image: registry.example.org/example/shop@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

image는 `source`와 같은 인스턴스 잠금 파일에 있으며 다음을 포함하는 정규화된 전체
소문자 OCI 참조여야 합니다.

- `localhost` 또는 DNS registry host
- 선택적인 숫자 registry port
- 저장소 경로
- 소문자 64자리 SHA-256 다이제스트

`nginx:latest` 같은 변경 가능한 tag는 거부됩니다. `source`와 `image`는 한 쌍이므로
하나를 제공하면 둘 다 필요합니다.

## 내부 컨텍스트

ApplicationSet이 `_context`를 주입하며 애플리케이션 메타데이터에서 정의하면 안
됩니다.

```yaml
_context:
  application: shop
  instance:
    type: production
  secrets:
    enabled: false
```

`application`은 유효한 워크로드 형식 이름이어야 합니다. `instance.type`은
`production`, `testing`, `preview` 중 하나입니다. 선택적 `secrets` 객체는
플랫폼만 제공합니다. 활성화할 때는 HTTPS `server` URL도 필요하며 애플리케이션
메타데이터에서 두 필드 중 어느 것도 정의하면 안 됩니다.

프리뷰 컨텍스트에는 다음 항목도 필요합니다.

```yaml
instance:
  type: preview
  workload: web
  pullRequest: 42
```

`workload`는 유효한 워크로드 이름이어야 합니다. `pullRequest`는 `1` 이상의
정수여야 합니다.
프로덕션 및 테스팅 컨텍스트에는 `workload`나 `pullRequest`를 포함하면 안 됩니다.

## 인스턴스 유형별 렌더링

### 프로덕션

- 모든 워크로드를 렌더링합니다.
- 모든 워크로드에 소스 및 이미지 잠금이 필요합니다.
- 구성된 복제본 수를 사용합니다.
- 각 domain에 프로덕션 라우팅 리소스를 생성합니다.
- external이 아닌 domain에는 HTTPS와 인증서를 제공합니다.

### 테스팅

- 모든 워크로드를 렌더링합니다.
- 모든 워크로드에 소스 및 이미지 잠금이 필요합니다.
- 구성된 복제본 수를 사용합니다.
- domain이 있는 워크로드는 `<application>.testing.scg.sh`를 통해 라우팅합니다.

### 프리뷰

- 선택한 워크로드만 렌더링합니다.
- 선택한 워크로드에만 소스 및 이미지 잠금이 필요합니다.
- 복제본 수를 `1`로 강제합니다.
- 호스트 이름에 애플리케이션, 워크로드, 풀 리퀘스트를 포함합니다.
- 다른 로컬 워크로드에 대한 참조는 테스팅 Service를 대상으로 합니다.
- `<application>-testing`에 `<application>-<workload>-<pull-request>`라는
  cross-namespace `ReferenceGrant`를 생성할 수 있습니다.

## 로컬 렌더링

저장소 루트에서 다음을 실행하세요.

```bash
helm template example-production argocd/charts/application \
  --values applications/example/meta.yaml \
  --values applications/example/instances/production.yaml \
  --set _context.application=example \
  --set _context.instance.type=production
```

Deployment, Service, 라우트, 인증서, 네임스페이스, 이미지 잠금을 검사하세요.
일반적인 검증을 위해 렌더링한 출력을 클러스터에 적용하지 마세요.

## 생성된 스키마

`values.schema.json`을 직접 편집하지 마세요.
[`values.schema.source.json`](values.schema.source.json)을 편집한 뒤 출력을 다시
생성하고 검사하세요.

```bash
k render application-schemas
k render application-schemas --check
```

생성된 스키마는 `state.yaml`에 고정된 Kubernetes 및 Gateway API 정의를 포함합니다.
