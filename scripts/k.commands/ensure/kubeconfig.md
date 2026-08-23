한국어 | [English](kubeconfig.en.md)

# kubeconfig

사용할 수 있는 로컬 Kubernetes 자격 증명을 확보합니다.

## 동작

기존 `kubeconfig`가 5초 안에 인증하고 네임스페이스 접근 권한을 확인할 수 있으면
파일을 유지하고 mode `600`을 적용합니다. 그렇지 않으면 주 Talos 노드에 대체 파일을
요청하고, Kubernetes API를 통해 대체 파일을 검증한 뒤 다른 kubeconfig와 병합하지
않고 원자적으로 설치합니다.

## 사용법

```bash
k ensure kubeconfig
```

## 전제 조건

- `talosconfig`가 있고 유효한 자격 증명을 포함합니다. 먼저
  `k ensure talosconfig`를 사용하세요.
- 주 Talos 노드와 Kubernetes API에 연결할 수 있습니다.

이 명령은 인자를 받지 않으며 클러스터 리소스를 변경하지 않습니다.
