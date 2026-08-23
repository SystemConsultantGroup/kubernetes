한국어 | [English](talosconfig.en.md)

# talosconfig

로컬 Talos 자격 증명이 선언된 클러스터 상태와 일치하도록 합니다.

## 동작

이 명령은 `state.yaml`의 클러스터 이름, endpoint, 설치 이미지, 버전과 암호화된
`secrets/talos.yaml`을 사용하여 예상 구성을 렌더링합니다. 주 노드를 endpoint로
구성하고 결과를 `talosconfig`와 비교합니다.

일치하는 파일은 유지합니다. 파일이 없거나 오래되었으면 원자적으로 교체합니다.
결과 파일은 mode `600`이며 복호화된 입력은 명령 종료 전에 제거되는 임시 파일에만
존재합니다.

## 사용법

```bash
k ensure talosconfig
```

## 전제 조건

- `state.yaml`에 클러스터 이름, endpoint, 버전이 정의되어 있습니다.
- 로컬 age 키로 `secrets/talos.yaml`을 복호화할 수 있습니다.

이 명령은 인자를 받지 않고 클러스터에 연결하거나 클러스터를 변경하지 않습니다.
실제 연결도 확인해야 한다면 Talos 작업 또는 상태 검사 명령을 사용하세요.
