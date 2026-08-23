한국어 | [English](me.en.md)

# me

로컬 age 키를 생성하거나 확인하고 수신자와 별칭을 출력합니다.

## 동작

설정된 경우 `SOPS_AGE_KEY_FILE`을 사용하고, 그렇지 않으면 기본값으로
`${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt`를 사용합니다.
파일이 없으면 상위 디렉터리를 만들고 키를 생성합니다.
그런 다음 파생된 수신자와 `secrets/state.yaml`에서 일치하는 모든 별칭을 출력합니다.

키 디렉터리는 mode `700`, 키 파일은 mode `600`으로 설정합니다.
이 명령은 로컬 키만 생성합니다. 수신자를 저장소에 추가하거나 암호화된 파일에 대한
접근 권한을 부여하지 않습니다.

## 사용법

```bash
k secrets recipients me
```

## 전제 조건

- `nix develop` 안에서 실행합니다.
- 키 디렉터리에 쓸 수 있고 `age-keygen`을 사용할 수 있습니다.

기존 키 경로가 일반 파일이 아니면 거부합니다.
이 명령은 인자를 받지 않습니다.
