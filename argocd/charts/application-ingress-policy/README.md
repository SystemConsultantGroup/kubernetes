한국어 | [English](README.en.md)

# 애플리케이션 ingress 정책 차트

이 플랫폼 차트는 관리형 애플리케이션의 프로덕션 도메인에 대해 하나의
`CiliumClusterwideNetworkPolicy`를 렌더링합니다.
`application-routing-policies` ApplicationSet은 각
`applications/*/meta.yaml` 파일을 읽고 `platform` AppProject를 통해 정책을
조정합니다.

공개 Gateway의 기본 정책은 인터넷 트래픽을 기본적으로 거부합니다. 이 차트는 HTTP
호스트가 선언된 프로덕션 도메인과 정확히 일치할 때만 `world` 트래픽을 허용합니다.
플랫폼 관리 TLS에는 포트 443을, `external: true`로 표시된 도메인에는 포트 80을
사용합니다. 테스팅 및 프리뷰 호스트 이름은 의도적으로 포함하지 않습니다. 기본
Gateway 정책은 해당 호스트를 `115.145.150.0/24`에서만 허용합니다.

이 차트는 애플리케이션 담당자용 인터페이스가 아니라 플랫폼 enforcement
코드입니다. 도메인 해석을
[`../application/templates/routing.yaml`](../application/templates/routing.yaml)의
라우팅 로직과 일치하도록 유지하세요.
