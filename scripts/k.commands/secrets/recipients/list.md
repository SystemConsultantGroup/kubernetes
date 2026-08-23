한국어 | [English](list.en.md)

# list

구성된 age 수신자를 나열하고 가능한 경우 로컬 수신자를 표시합니다.

## 동작

`secrets/state.yaml`에서 별칭을 읽고 별칭순으로 정렬한 뒤 각 별칭과 수신자를
출력합니다.
일치하는 로컬 수신자에는 `(me)`를 표시합니다.

이 명령은 없는 로컬 키를 생성하거나 저장소 파일을 변경하지 않습니다.
키가 있으면 `age-keygen`으로 비교할 로컬 수신자를 파생합니다.

## 사용법

```bash
k secrets recipients list
```

## 전제 조건

- `nix develop` 안에서 실행합니다.
- `secrets/state.yaml`과 `yq`가 있습니다.
- 로컬 키가 있다면 `age-keygen`으로 읽을 수 있습니다.

키 경로는 설정된 경우 `SOPS_AGE_KEY_FILE`이고, 그렇지 않으면
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`입니다.
이 명령은 인자를 받지 않습니다.
