한국어 | [English](README.en.md)

# 비활성 RFC2136 DNS 예시

이 디렉터리는 `scg.skku.ac.kr`용 ExternalDNS 인스턴스 후보를 위한 참조 자료입니다.
파일은 `.example`로 끝나고 Argo CD 루트에 포함되지 않으며 클러스터에 영향을 주지
않습니다.

파일 이름만 바꾸어 예시를 활성화하지 마세요. rollout에는 승인된 RFC2136 endpoint와
TSIG secret, 고유 TXT owner ID, 좁은 domain filter, 루트 Kustomization에 포함된
Argo CD Application, 활성 Cloudflare 인스턴스와 함께 수행하는 레코드 소유권 검토가
필요합니다.

이 디렉터리에 자격 증명을 넣지 마세요. 설계가 승인되면 조정을 활성화하기 전에
레코드 소유권과 운영 절차를 이곳에 문서화하세요.
