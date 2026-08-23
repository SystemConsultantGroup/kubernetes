한국어 | [English](README.en.md)

# Reloader

이 구성 요소는 참조된 Secret 또는 ConfigMap이 변경되면 관리형 Deployment를
재시작합니다. `platform.scg.sh/application` label로 선택된 네임스페이스에서만
실행되며 annotation 기반 rollout trigger를 사용합니다.

관리형 Vault 연동이 활성화되면 애플리케이션 차트가 워크로드를 Secret reload 대상에
포함합니다. ApplicationSet은 Argo CD가 Reloader의 pod template annotation을
무시하도록 구성하므로 자동 복구가 rollout을 즉시 되돌리지 않습니다. 참조된 구성을
생성하거나 삭제해도 reload를 시작하며 Job과 CronJob은 무시합니다.

차트 버전 고정을 [`../../../state.yaml`](../../../state.yaml)의 `reloader.chart`와
동기화하세요. 네임스페이스 selector 또는 reload 전략 변경은 모든 관리형
애플리케이션에 영향을 줄 수 있습니다. 예상하지 못한 restart를 진단할 때는
애플리케이션 복제본이나 이미지를 변경하기 전에 Deployment annotation과 Reloader
이벤트를 확인하세요.
