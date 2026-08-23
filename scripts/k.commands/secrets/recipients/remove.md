한국어 | [English](remove.en.md)

# remove

이름이 지정된 age 수신자를 제거하고 저장소의 암호화된 모든 시크릿의 키를 다시
설정합니다.

> [!CAUTION]
> 암호화된 모든 파일의 rekey가 성공한 뒤에만 해당 수신자의 접근 권한이 취소됩니다.
> 이 명령은 대화형 입력 없이 실행되며 확인을 요청하지 않습니다.

## 동작

이 명령은 알 수 없는 별칭과 마지막으로 구성된 수신자의 제거를 거부합니다.
유효한 별칭이면 `secrets/state.yaml`을 갱신하고 `.sops.yaml`을 다시 생성한 뒤
암호화된 모든 최상위 YAML 파일에 `sops updatekeys --yes`를 실행합니다.

rekey가 실패하면 수신자 맵, `.sops.yaml`, 시크릿 파일을 백업에서 복원합니다.

## 사용법

```bash
k secrets recipients remove <name>
```

이 명령은 정확히 하나의 별칭을 받으며 플래그는 받지 않습니다.

## 전제 조건

- `nix develop` 안에서 실행합니다.
- `secrets/state.yaml`과 `.sops.yaml`이 있습니다.
- 로컬 age 키로 SOPS가 기존 암호화된 시크릿을 복호화하고 rekey할 수 있습니다.
