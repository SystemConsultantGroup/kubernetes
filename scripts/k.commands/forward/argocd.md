한국어 | [English](argocd.en.md)

# argocd

Argo CD 서버를 `http://localhost:8080`으로 포워딩합니다.

## 동작

다음 명령을 실행합니다.

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
```

로컬 포트 8080을 `argocd` 네임스페이스의 `argocd-server` Service에 연결합니다.
Argo CD는 Service 뒤에서 HTTP를 사용하도록 구성되어 있으므로
`http://localhost:8080`을 여세요.
프로세스는 foreground에서 계속 실행됩니다. 중지하려면 Ctrl+C를 누르세요.

## 사용법

```bash
k forward argocd
```

## 전제 조건

- `kubeconfig`가 있고 클러스터에 연결할 수 있습니다.
- Argo CD가 설치되어 있고 `argocd-server` Service가 정상입니다.

이 명령은 인자를 받지 않습니다.
