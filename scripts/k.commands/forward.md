한국어 | [English](forward.en.md)

# forward

클러스터 서비스를 로컬 머신의 포트로 포워딩합니다.

## 명령

- `argocd`는 Argo CD 서버를 `http://localhost:8080`으로 포워딩합니다.

## 사용법

```text
k forward <command> [args...]
```

`k forward`를 실행하면 하위 명령을 나열합니다.
이 페이지는 `k forward --help`로 확인하세요.

## 전제 조건

- 개발 셸이 활성화되어 있고 `kubeconfig`가 있습니다.
- 클러스터에 연결할 수 있습니다.
- 대상 서비스가 설치되어 있고 정상입니다.

## 동작

포워딩은 foreground에서 실행됩니다.
활성 포워딩을 중지하려면 Ctrl+C를 누르세요.
이 명령은 클러스터 리소스를 변경하지 않습니다.
