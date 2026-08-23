한국어 | [English](secrets.en.md)

# secrets

SOPS로 암호화된 YAML 파일과 age 수신자를 관리합니다.

## 하위 명령

- `check`는 로컬 수신자, `.sops.yaml`, 암호화된 모든 시크릿을 검증합니다.
- `edit <secret>`은 SOPS로 `secrets/<secret>.yaml`을 엽니다.
- `recipients`는 구성된 age 수신자를 관리합니다.

## 사용법

```bash
k secrets <command> [args...]
```

`k secrets`를 실행하면 하위 명령을 나열합니다.
이전 단수 표기인 `k secrets recipient`도 `recipients`의 별칭으로 유지됩니다.

## 전제 조건

`yq`, `sops`, `age`, `age-keygen`을 제공하는 `nix develop` 안에서 실행하세요.
시크릿 명령은 의도적으로 클러스터 `state.yaml`을 불러오지 않으므로 클러스터 상태가
잘못되었거나 불완전한 동안에도 운영자가 암호화 접근을 복구할 수 있습니다.

## 동작

`secrets/state.yaml`은 공개 수신자 맵입니다.
이 명령은 해당 맵과 암호화된 파일에서 루트
[`.sops.yaml`](../../.sops.yaml)을 생성합니다.
시크릿을 편집하면 생성된 구성을 동기화합니다. 수신자를 추가하거나 제거하면
`secrets/` 아래의 암호화된 모든 최상위 YAML 파일의 키도 다시 설정합니다.

복호화된 값을 출력하거나 명시적인 접근 권한 변경 승인 없이 수신자를 변경하지 마세요.
