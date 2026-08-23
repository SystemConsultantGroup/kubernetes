한국어 | [English](README.en.md)

# Argo CD

이 Application은 Argo CD 차트, 저장소 values, 네임스페이스 메타데이터,
`https://argocd.platform.scg.sh`의 공개 라우트를 소유합니다.

## 부트스트랩 및 소유권

`k install argocd`는 루트 Application을 생성하기 전에 같은 고정 차트와 values를
렌더링하고 적용합니다. 루트가 조정되면 이 Application이 정리와 자동 복구를 사용하여
지속적인 소유권을 인계받습니다. 일반 업그레이드에는 부트스트랩 명령을 다시 실행하지
말고 Git을 통해 `argocd.version`, 이 Application의 리비전, 차트 values를
갱신하세요.

## 라우팅

`argocd` HTTPRoute는 공개 Gateway의 `platform-https` listener에 연결되고 Service
포트 80의 `argocd-server`로 전달합니다. TLS는 공유 `*.platform.scg.sh` 인증서를
사용하여 Gateway에서 종료됩니다.

Argo CD Helm values는 `/applicationset-webhook`용 별도 ApplicationSet webhook
라우트를 생성합니다. 기본 API webhook은 계속 `/api/webhook`에서 사용할 수 있습니다.
두 GitHub webhook은 같은 암호화된 Secret을 사용하지만 서로 다른 controller에
알립니다.

## 조정

플랫폼 Application은 Gateway와 wildcard 인증서 Application이 조정을 시작한 뒤인
sync wave 3에서 실행됩니다. 호스트 이름, 상위 listener, Helm domain, GitHub
webhook 구성을 함께 변경하세요.
