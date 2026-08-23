한국어 | [English](check.en.md)

# check

로컬 age 수신자, 생성된 SOPS 구성, 암호화된 시크릿 파일을 검사합니다.

## 동작

이 명령은 다음을 검증합니다.

- 로컬 age 키에서 파생된 수신자가 `secrets/state.yaml`에 있습니다.
- `.sops.yaml`이 생성된 구성과 일치합니다.
- 암호화된 모든 최상위 `secrets/*.yaml` 파일을 정상적으로 복호화할 수 있습니다.

복호화된 각 파일에 대해 `OK: <path>`를 출력하고 마지막에 로컬 `Recipient`를
출력합니다. `secrets/state.yaml` 자체는 암호화된 파일 검사에서 제외됩니다.

## 사용법

```bash
k secrets check
```

## 전제 조건

- `nix develop` 안에서 실행합니다.
- `secrets/state.yaml`, `.sops.yaml`, 로컬 age 키가 있습니다.
- `secrets/` 아래에 암호화된 YAML 파일이 하나 이상 있습니다.
- 로컬 수신자가 수신자 맵에 이미 추가되어 있습니다.

키 경로는 설정된 경우 `SOPS_AGE_KEY_FILE`이고, 그렇지 않으면
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`입니다.
이 명령은 인자를 받지 않으며 비교용 임시 파일 하나만 생성합니다.
