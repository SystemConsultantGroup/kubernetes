한국어 | [English](render.en.md)

# render

상태에서 파생된 스키마와 Kubernetes 매니페스트를 렌더링합니다.

## 사용법

```bash
k render
k render <command>
```

하위 명령 없이 `k render`를 실행하면 커밋된 애플리케이션 스키마를 갱신한 뒤
무시된 `.rendered/` 매니페스트 트리를 다시 생성합니다.

## 하위 명령

- `application-schemas`는 커밋된 관리형 애플리케이션 스키마를 렌더링하거나
  검사합니다.
- `manifests`는 검사를 위해 부트스트랩, GitOps 루트, 플랫폼, 애플리케이션
  매니페스트를 렌더링합니다.

렌더링은 실제 클러스터에 연결하거나 클러스터를 변경하지 않습니다. `state.yaml`에
고정된 버전의 산출물을 다운로드하므로 네트워크 접근이 필요합니다.
