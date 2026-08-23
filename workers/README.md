한국어 | [English](README.en.md)

# Cloudflare Worker

이 디렉터리에는 Kubernetes 클러스터와 별도로 배포되는 에지 서비스가 있습니다.
각 Worker는 자체 Wrangler 구성, 의존성, 테스트, 운영 문서를 관리합니다.

Worker는 Argo CD가 조정하지 않습니다. 구성된 Cloudflare 라우트와 시크릿을
검토한 뒤 각 디렉터리에서 명시적으로 배포하세요.

- [`kms`](kms/)는 Vault 자동 봉인 해제에 사용하는 최소 Vault Transit 호환
  서비스를 제공합니다.
