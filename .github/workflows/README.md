한국어 | [English](README.en.md)

# 애플리케이션 배포 워크플로

애플리케이션 저장소는 재사용 가능한 [`build-image.yaml`](build-image.yaml)
워크플로를 사용합니다. 이 워크플로는 저장소 루트를 컨텍스트로 사용하여 루트
`Dockerfile`을 빌드하고, 변경 불가능한 이미지를 게시하고, 빌드 출처를 기록한 뒤
이 저장소의 [`apply.yaml`](apply.yaml)을 디스패치합니다.

`apply.yaml`은 `instance-updates` 큐를 통해 인스턴스 변경을 직렬화합니다.
프로덕션 또는 테스팅 워크로드 잠금을 설정하고, 프리뷰 잠금을 생성 및 갱신하며,
풀 리퀘스트가 닫히면 프리뷰 잠금을 제거합니다. 클러스터에는 절대 접근하지 않습니다.
Argo CD가 결과로 생성된 `main` 커밋을 감지합니다.

## 애플리케이션 워크플로

애플리케이션 저장소에 작은 워크플로를 추가하고 재사용 워크플로를 Kubernetes의 전체
커밋으로 고정하세요.

```yaml
name: Container

on:
  pull_request:
    types:
      - opened
      - reopened
      - synchronize
      - closed
  push:
    branches:
      - main
      - testing

permissions:
  attestations: write
  contents: read
  id-token: write
  packages: write

jobs:
  build-image:
    uses: SystemConsultantGroup/kubernetes/.github/workflows/build-image.yaml@0123456789abcdef0123456789abcdef01234567
    with:
      application: example
      workload: fe
      image: ghcr.io/systemconsultantgroup/kubernetes-example
      build_args: |
        NEXT_PUBLIC_OAUTH_CLIENT_ID=${{ vars.NEXT_PUBLIC_OAUTH_CLIENT_ID }}
    secrets:
      KUBERNETES_APP_ID: ${{ secrets.KUBERNETES_APP_ID }}
      KUBERNETES_APP_PRIVATE_KEY: ${{ secrets.KUBERNETES_APP_PRIVATE_KEY }}
```

## 브랜치와 인스턴스 대응

정확한 브랜치 이름에 따라 다음과 같이 대응됩니다. 워크플로에 나열된 브랜치 순서는
관계없습니다.

| 애플리케이션 이벤트 | 인스턴스 변경 |
| --- | --- |
| `main`에 푸시 | 프로덕션 갱신 |
| `testing`에 푸시 | 테스팅 갱신 |
| 같은 저장소의 풀 리퀘스트를 열거나 갱신 | 해당 풀 리퀘스트의 프리뷰 생성 또는 갱신 |
| 같은 저장소의 풀 리퀘스트를 닫음 | 해당 풀 리퀘스트의 프리뷰 제거 |

`main`이나 `testing`이 아닌 브랜치에서 푸시하면 거부됩니다. 풀 리퀘스트는 GitHub가
제안한 병합 커밋을 빌드하므로 프리뷰에서 병합 결과 코드를 실행합니다. 포크 풀
리퀘스트는 거부되며 `pull_request_target`은 지원하지 않습니다.

애플리케이션 테스트는 `build-image` 전에 별도 작업으로 실행할 수 있습니다. 풀
리퀘스트를 닫을 때도 프리뷰 잠금을 제거할 수 있도록 재사용 워크플로를 호출해야 합니다.

## 레지스트리 구성

`image` 입력의 정규화된 전체 저장소에 따라 인증 방식이 선택됩니다.

- `ghcr.io`는 호출자의 `GITHUB_TOKEN`을 사용하며 `packages: write`가 필요합니다.
- `docker.io`에는 명시적으로 전달한 `DOCKERHUB_USERNAME` 및 `DOCKERHUB_TOKEN`
  시크릿이 필요합니다.

이미지는 다이제스트로만 배포됩니다. 사람이 읽을 수 있는 커밋 태그는 검사를 위해
게시하지만 인스턴스 잠금 파일에는 절대 기록하지 않습니다.

## 빌드 시점 구성

선택적 `build_args`는 애플리케이션 저장소에서 루트 `Dockerfile`로 비밀이 아닌
`KEY=VALUE` 형식의 Docker 빌드 인자를 줄마다 하나씩 전달합니다. 재사용할 공개 값은
해당 애플리케이션 저장소의 GitHub Actions Variables에 저장하고, Dockerfile에 필요한
값만 전달하세요. 예를 들어 Next.js OAuth 클라이언트 ID는
`NEXT_PUBLIC_OAUTH_CLIENT_ID`에 두며, `next build`를 실행하는 Dockerfile stage에서
같은 이름을 `ARG`로 선언합니다.

Next.js는 `NEXT_PUBLIC_*` 값을 브라우저 번들에 컴파일합니다. 이는 공개 값이며 빌드
시점에 올바른 값이어야 합니다. `build_args`에는 클라이언트 시크릿, 토큰, 자격 증명 등
민감한 값을 넣지 마세요. 빌드 메타데이터나 이미지 이력에 남을 수 있습니다. 런타임
환경변수와 민감한 값은 애플리케이션의 Kubernetes 구성 및 관리형 Secret으로 설정하세요.

## 디스패치 권한 부여

애플리케이션 저장소에는 `KUBERNETES_APP_ID`와 `KUBERNETES_APP_PRIVATE_KEY`가
필요합니다. 해당 GitHub App은 이 저장소에만 설치해야 하며 `Actions: write` 권한이
필요합니다. 이 토큰은 `apply.yaml`을 디스패치할 수 있지만 저장소 내용은 변경할 수
없습니다.

apply 워크플로는 모든 디스패치를 신뢰하지 않는 입력으로 취급합니다. 프로덕션 잠금
파일에서 소스 및 이미지 저장소와 이미 연결된 애플리케이션과 워크로드만 변경할 수
있도록 제한합니다. 결과 커밋은 자체 `GITHUB_TOKEN`으로 생성합니다.
