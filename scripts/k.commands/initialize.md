한국어 | [English](initialize.en.md)

# initialize

GitOps 이후 필요한 권한 있는 서비스 초기화를 수행합니다.

## 명령

- `vault`는 새로운 Vault 저장소를 초기화하고 권한 있는 API를 구성하거나, 유효한
  부트스트랩 root 토큰이 남아 있는 동안 구성을 조정합니다.

## 사용법

```bash
k initialize <command>
```

`k initialize`를 실행하면 하위 명령을 나열합니다. 초기화는 실제 상태를 변경하며,
Argo CD 루트 부트스트랩 후에 중지하는 `k install`과 의도적으로 분리되어 있습니다.
