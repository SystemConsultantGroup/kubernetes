한국어 | [English](README.en.md)

# Gateway API 정의

이 Application은 `state.yaml`에 고정된 버전의 upstream 표준 Gateway API CRD를
조정합니다. Envoy Gateway와 플랫폼 Gateway가 이 클러스터 범위 정의에 의존하며,
Cilium은 더 이상 Gateway API 리소스를 조정하지 않습니다.

Cilium 전에는 Argo CD를 실행할 수 없으므로 초기 CRD는 공식 release 산출물에서
렌더링되어 `k install cilium`으로 적용됩니다. 루트 Application이 생성된 후에는
Argo CD가 일치하는 upstream Git tag에서 정의를 직접 소유합니다.

상태 버전 고정과 이 Application의 리비전을 함께 갱신하세요. CRD 버전을 변경하기
전에 변환, storage version, Cilium 호환성 참고 사항을 검토하세요.
