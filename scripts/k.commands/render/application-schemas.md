한국어 | [English](application-schemas.en.md)

# application-schemas

관리형 애플리케이션 차트 스키마를 렌더링하거나 검사합니다.

## 동작

이 명령은 고정된 Kubernetes OpenAPI 문서와 Gateway API `HTTPRoute` CRD를
다운로드하고, 애플리케이션 메타데이터에 사용하는 타입을 선택한 뒤 해당 정의를 차트의
소스 스키마와 병합합니다.
설명을 제거하고, 구조화된 객체를 엄격하게 만들고, Kubernetes `IntOrString`을
정규화한 뒤 다음 파일을 기록합니다.

```text
argocd/charts/application/values.schema.json
```

`--check`는 생성 결과를 커밋된 파일과 비교하고 오래된 경우 오류와 함께 종료합니다.
파일은 변경하지 않습니다.

## 사용법

```bash
k render application-schemas
k render application-schemas --check
```

## 전제 조건

- `state.yaml`에 `kubernetes.version`과 `gateway-api.version`이 있습니다.
- `curl`, `jq`, `yq`를 사용할 수 있습니다.
- `raw.githubusercontent.com`에 있는 고정된 정의에 네트워크로 접근할 수 있습니다.

생성된 스키마가 아니라 `values.schema.source.json`을 편집한 뒤 `--check` 없이
명령을 실행하고 diff를 검토하세요.
