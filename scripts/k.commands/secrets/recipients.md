한국어 | [English](recipients.en.md)

# recipients

저장소 시크릿을 복호화할 수 있는 age 수신자를 관리합니다.

## 하위 명령

- `add <name> <recipient>`는 수신자를 추가하고 암호화된 모든 시크릿의 키를 다시 설정합니다.
- `list`는 별칭을 나열하고 로컬 수신자에 `(me)`를 표시합니다.
- `me`는 로컬 age 키를 생성하거나 확인하고 수신자를 출력합니다.
- `remove <name>`은 수신자를 제거하고 암호화된 모든 시크릿의 키를 다시 설정합니다.

## 사용법

```bash
k secrets recipients <command> [args...]
```

`k secrets recipients`를 실행하면 하위 명령을 나열합니다.
`add`와 `remove` 명령은 `secrets/state.yaml`을 갱신하고 `.sops.yaml`을 다시
생성하며 암호화된 모든 최상위 YAML 파일에 대화형 입력 없이 SOPS rekey를 실행합니다.

> [!CAUTION]
> 추가하면 암호화된 모든 시크릿에 대한 접근 권한을 부여합니다.
> 제거는 rekey가 성공한 뒤에만 접근 권한을 취소합니다.
> 변경 전에 수신자와 별칭을 검토하세요.

## 전제 조건

- `nix develop` 안에서 실행합니다.
- `add`, `list`, `remove`에는 `secrets/state.yaml`이 필요합니다.
- `add`와 `remove`에는 `.sops.yaml`이 필요합니다.
- `add`와 `remove`를 실행하려면 로컬 age 키로 기존 시크릿을 복호화하고 rekey할 수
  있어야 합니다.
