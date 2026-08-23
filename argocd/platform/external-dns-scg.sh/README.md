한국어 | [English](README.en.md)

# scg.sh용 ExternalDNS

이 구성 요소는 Cloudflare를 통해 `scg.sh` 아래의 Gateway API HTTPRoute용 DNS
레코드를 게시합니다. ListenerSet을 포함한 Gateway 라우트를 감시하며
[`../../../state.yaml`](../../../state.yaml)에 고정된 차트 버전으로 실행됩니다.

## 소유권 및 범위

ExternalDNS는 `domainFilters`로 `scg.sh`에 제한됩니다. owner ID `scg.sh`로 TXT
registry를 사용하므로 소유권 표식이 있는 레코드만 관리합니다. policy는 `sync`이므로
소유한 목표 레코드를 제거하면 Cloudflare에서도 삭제될 수 있습니다.

`k install argocd`는 암호화된 부트스트랩 값으로
`external-dns/cloudflare-api-token`을 생성합니다. 토큰에는 관련 zone의 읽기 권한과
DNS 편집 권한이 필요합니다. `values.yaml`에 넣지 마세요.

공개 Gateway와 애플리케이션 차트는 annotation으로 wildcard 플랫폼, 테스팅,
프리뷰 레코드를 게시합니다. `external: true`로 표시된 프로덕션 도메인에는 제외
annotation이 있으며 외부 DNS 운영자가 계속 담당합니다.

## 변경

차트 버전 고정을 `state.yaml`의 `external-dns.version`과 동기화하세요.
이 구성 요소를 변경하기 전에 `domainFilters`, TXT 소유권, 소스 kind, 삭제 동작을
검토하세요. DNS migration 전에 ExternalDNS의 계획된 endpoint log를 검사하세요.
이 controller가 소유하는 레코드의 영구 목표 상태로 provider를 직접 편집하지 마세요.
