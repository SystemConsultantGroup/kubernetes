한국어 | [English](ensure.en.md)

# ensure

로컬 Talos 및 Kubernetes 자격 증명이 최신이며 사용할 수 있는지 확인합니다.

## 사용법

```bash
k ensure
k ensure <command>
```

하위 명령 없이 `k ensure`를 실행하면 먼저 `talosconfig`를 확인하고 그다음
`kubeconfig`를 확인합니다. kubeconfig 단계에는 사용 가능한 Kubernetes 클러스터가
필요하므로 초기 부트스트랩 중에는 적절한 시점에 개별 명령을 사용하세요.

## 하위 명령

- `talosconfig`는 로컬 구성을 `state.yaml` 및 암호화된 Talos 시크릿과 비교하고,
  없거나 오래된 경우에만 교체합니다.
- `kubeconfig`는 Kubernetes API에 연결할 수 있는 kubeconfig를 유지하며, 그렇지
  않으면 Talos를 통해 대체 파일을 가져옵니다.

두 파일 모두 저장소 루트에 mode `600`으로 기록되며 Git에서 무시됩니다.
이 명령들은 클러스터 리소스를 변경하지 않습니다.
