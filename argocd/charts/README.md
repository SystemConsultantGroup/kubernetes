한국어 | [English](README.en.md)

# Helm 차트

이 디렉터리에는 Argo CD에서 사용하는 Helm 차트가 있습니다.
[`application/`](application/)은 메타데이터, 변경 불가능한 잠금 파일, 내부
인스턴스 컨텍스트를 사용하여 관리형 애플리케이션 인스턴스를 렌더링합니다.
[`application-ingress-policy/`](application-ingress-policy/)는 이에 대응하는 공개
프로덕션 호스트 정책을 렌더링합니다.

애플리케이션 차트는 관리형 애플리케이션 스키마, 리소스 이름, 워크로드 렌더링,
Gateway 라우팅 동작을 소유합니다. ingress 정책 차트는 Gateway 정책이 테스팅과
프리뷰를 제한하는 동안 프로덕션을 공개 상태로 유지합니다. 애플리케이션 담당자는
[`applications/` 워크플로](../../applications/)로 시작해야 합니다. 고급 구성과
플랫폼 변경을 위한 전체 필드 및 렌더링 참조는
[차트 README](application/README.md)에 있습니다.

이 차트는 범용 애플리케이션 차트가 아니라 플랫폼 코드입니다.
변경 하나가 모든 관리형 애플리케이션에 영향을 줄 수 있습니다.
풀 리퀘스트를 열기 전에 영향을 받는 values를 로컬에서 렌더링하고 Deployment,
Service, 라우트, 인증서, 네임스페이스, 이미지 잠금을 검사하세요.
일반 차트 검증을 위해 렌더링한 출력을 실제 클러스터에 적용하지 마세요.
