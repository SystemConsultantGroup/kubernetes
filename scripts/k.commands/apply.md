한국어 | [English](apply.en.md)

# apply

생성된 Talos 머신 구성을 `state.yaml`의 모든 노드에 적용합니다.

## 동작

이 명령은 먼저 `secrets/talos.yaml`을 복호화하고, 선언된 각 노드의 control plane
구성을 생성하고, 노드 및 공유 패치를 적용한 뒤 모든 결과를 엄격한 metal 모드로
검증합니다. 모든 구성이 로컬 검증을 통과하기 전에는 어떤 노드도 변경하지 않습니다.

구성된 노드에는 인증된 Talos 연결을 사용합니다. 인증되지 않은 machine-status
endpoint에서 노드가 maintenance 모드임을 확인한 경우에만 `--insecure`를 사용합니다.
그 밖의 인증 실패가 발생하면 명령을 중단합니다. 확인 질문이나 dry-run 모드는 없으며
항상 선언된 모든 노드를 대상으로 합니다.

## 사용법

```bash
k apply
```

## 전제 조건

- `nix develop` 안에서 실행합니다.
- `state.yaml`에 클러스터, 버전, endpoint, 노드가 정의되어 있습니다.
- 로컬 age 키로 `secrets/talos.yaml`을 복호화할 수 있습니다.
- `patches/<node>.yaml`, `patches/worker.yaml`, `patches/cilium.yaml`이 있습니다.

실제 작업을 실행하기 전에 노드 주소, 디스크 선택자, 의도한 버전 변경을 검토하세요.
명령이 종료되면 임시로 복호화하거나 생성한 파일을 제거합니다.
