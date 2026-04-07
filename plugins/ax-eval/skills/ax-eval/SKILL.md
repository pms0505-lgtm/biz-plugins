---
name: ax-eval
description: "AX-Eval — 사업관리본부 AI 전환(AX) 레벨 평가. Claude Code 로그를 자동 분석하여 4축 레벨 체크 + 맞춤 활용 팁 제공."
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Task
  - Agent
---

# /ax-eval 커맨드

사업관리본부 직원들의 AI 활용 수준(AX 레벨)을 측정하고 성장을 추적합니다.

## 명령어

| 인자 | 별칭 | 설명 | 스킬 |
|------|------|------|------|
| `시작` | `start`, `onboard`, `setup` | 처음 설치 시 1회 실행 | ax-eval-onboard |
| `체크` | `check`, `평가`, `레벨` | 내 AX 레벨 자동 분석 | ax-eval-check |
| `팁` | `tip`, `가이드`, `guide` | 현재 레벨 맞춤 활용 팁 | ax-eval-tip |

## 사용 방법

```
/ax-eval 시작   # 처음 한 번만
/ax-eval 체크   # 레벨 확인 (주 1회 권장)
/ax-eval 팁     # 활용법 추천
```

---

## 라우팅 로직

인자를 분석하여 적절한 스킬로 위임합니다.

**인자가 없거나 도움말 요청:**
- 위 사용 방법 안내 출력

**`시작` / `start` / `onboard` / `setup`:**
- `ax-eval-onboard` 스킬 실행

**`체크` / `check` / `평가` / `레벨`:**
- `ax-eval-check` 스킬 실행

**`팁` / `tip` / `가이드` / `guide`:**
- `ax-eval-tip` 스킬 실행

**알 수 없는 인자:**
- "알 수 없는 명령어입니다. `/ax-eval 시작`, `/ax-eval 체크`, `/ax-eval 팁` 중 하나를 사용해주세요." 출력
