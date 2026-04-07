---
name: ax-eval-check
description: "AX 레벨 체크. Claude Code 로그를 자동 분석하여 4축 점수 + 별점 레벨을 출력."
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - Agent
---

# ax-eval-check: AX 레벨 체크

Claude Code 대화 로그를 자동 분석하여 현재 AI 활용 수준(AX 레벨)을 측정합니다.

---

## 실행 순서

### 1단계: 최신 로그 변환

플러그인의 convert_sessions.py를 실행하여 새 세션을 반영합니다:

```bash
python3 {PLUGIN_SCRIPTS_DIR}/convert_sessions.py \
  --output-dir ~/ax-eval/conversations \
  --names-file ~/ax-eval/config/project_names.json
```

> `{PLUGIN_SCRIPTS_DIR}`는 플러그인 설치 경로의 scripts/ 디렉토리로 자동 해결됩니다.

### 2단계: ax-analyst 서브에이전트에 위임

```
ax-analyst 서브에이전트를 실행하여 로그 분석 및 레벨 산출을 위임합니다.
결과를 받아 아래 형식으로 출력합니다.
```

### 3단계: 결과 출력

ax-analyst의 결과를 받아 다음 형식으로 출력합니다:

**데이터 부족 시:**
```
📊 AX 레벨 체크 — YYYY-MM-DD

아직 데이터가 부족합니다 (N개 세션).
Claude Code를 조금 더 사용하신 후 다시 체크해보세요!

💡 최소 3개 세션 이상이면 레벨 측정이 가능합니다.
   /ax-eval 팁 으로 먼저 활용법을 확인해보세요.
```

**정상 분석 시 (첫 평가):**
```
📊 AX 레벨 체크 — YYYY-MM-DD

종합: {STAR} {LEVEL_NAME} (첫 평가)

| 축     | 점수  | 레벨    |
|--------|-------|---------|
| 요청력 | {score} | {bar} |
| 검증력 | {score} | {bar} |
| 활용력 | {score} | {bar} |
| 판단력 | {score} | {bar} |

분석된 세션: {N}개{DATA_NOTE}

💡 가장 낮은 축: {WEAKEST_AXIS}
   → {WEAKEST_TIP}

📈 성장하려면: /ax-eval 팁
```

> `{DATA_NOTE}`: SESSIONS_ANALYZED가 3~5이면 ` (데이터 부족, 정확도가 낮을 수 있음)` 추가. 6개 이상이면 빈 문자열.

**정상 분석 시 (재평가 — 레벨 유지 또는 상승):**
```
📊 AX 레벨 체크 — YYYY-MM-DD

종합: {STAR} {LEVEL_NAME} {🎉레벨업시만}  {PREV_COMPOSITE_SCORE} → {COMPOSITE_SCORE}점 ({COMPOSITE_DELTA}점 ↑)

| 축     | 이전  | 지금  | 변화       | 레벨    |
|--------|-------|-------|------------|---------|
| 요청력 | {prev} | {score} | {delta} {방향} | {bar} |
| 검증력 | {prev} | {score} | {delta} {방향} | {bar} |
| 활용력 | {prev} | {score} | {delta} {방향} | {bar} |
| 판단력 | {prev} | {score} | {delta} {방향} | {bar} |

분석된 세션: {N}개{DATA_NOTE}

💡 가장 낮은 축: {WEAKEST_AXIS}
   → {WEAKEST_TIP}

📈 성장하려면: /ax-eval 팁
```

**정상 분석 시 (재평가 — 레벨 하락):**
```
📊 AX 레벨 체크 — YYYY-MM-DD

종합: {STAR} {LEVEL_NAME}  {PREV_COMPOSITE_SCORE} → {COMPOSITE_SCORE}점 ({COMPOSITE_DELTA}점 ↓)

| 축     | 이전  | 지금  | 변화       | 레벨    |
|--------|-------|-------|------------|---------|
| 요청력 | {prev} | {score} | {delta} {방향} | {bar} |
| 검증력 | {prev} | {score} | {delta} {방향} | {bar} |
| 활용력 | {prev} | {score} | {delta} {방향} | {bar} |
| 판단력 | {prev} | {score} | {delta} {방향} | {bar} |

분석된 세션: {N}개{DATA_NOTE}

📉 이번 주 사용량이 적거나 업무 유형이 바뀌면 점수가 내려갈 수 있어요.
   일시적인 변화이니 너무 걱정하지 마세요.

💡 가장 많이 내려간 축: {MOST_DROPPED_AXIS}
   → {WEAKEST_TIP}

📈 다시 올리려면: /ax-eval 팁
```

### 출력 형식 규칙

**`{DATA_NOTE}` 규칙:**
- SESSIONS_ANALYZED 3~5: ` (데이터 부족, 정확도가 낮을 수 있음)` 출력
- SESSIONS_ANALYZED 6 이상: 빈 문자열 (출력 없음)

**별점 표시:**
- ⭐ 입문 (1.0 이상 1.8 미만)
- ⭐⭐ 활용 (1.8 이상 2.6 미만)
- ⭐⭐⭐ 협업 (2.6 이상 3.4 미만)
- ⭐⭐⭐⭐ 주도 (3.4 이상 4.2 미만)
- ⭐⭐⭐⭐⭐ 전략 (4.2 이상 5.0 이하)

**점수 바:**
- 1.0~1.9: `▓░░░░`
- 2.0~2.9: `▓▓░░░`
- 3.0~3.9: `▓▓▓░░`
- 4.0~4.9: `▓▓▓▓░`
- 5.0: `▓▓▓▓▓`

**변화 표시 규칙:**
- delta > 0: `+{delta}점 ↑` (예: `+0.8점 ↑`)
- delta < 0: `{delta}점 ↓` (예: `-0.3점 ↓`)
- delta = 0: `→ (유지)`
- 첫 평가: 이전/변화 열 없이 점수+레벨만 표시

**{STAR} 생성 규칙**: ax-analyst가 반환한 LEVEL 숫자(1~5)를 ⭐ 개수로 변환. LEVEL=2 → ⭐⭐

**종합 줄 표시 예시:**
- 점수↑ 레벨 유지: `⭐⭐⭐ 협업  2.4 → 2.8점 (+0.4점 ↑)`
- 점수↑ 레벨 업: `⭐⭐⭐ 협업 🎉  2.4 → 2.8점 (+0.4점 ↑)`
- 점수↓ 레벨 유지: `⭐⭐⭐ 협업  3.2 → 2.9점 (-0.3점 ↓)`
- 점수↓ 레벨 다운: `⭐⭐ 활용  2.7 → 2.3점 (-0.4점 ↓)` + 📉 안내 블록
- 유지: `⭐⭐⭐ 협업  2.8 → 2.8점 (→ 유지)`

**레벨 하락 시 추가 규칙:**
- `📉` 안내 블록은 LEVEL 숫자가 내려갔을 때만 출력 (점수만 내려간 경우는 생략)
- `{MOST_DROPPED_AXIS}`: ax-analyst 반환값 `MOST_DROPPED_AXIS` 그대로 사용. `없음`이면 `{WEAKEST_AXIS}` 대신 사용
- 격려 어조 유지 — "잘못됐다"가 아닌 "일시적 변화" 프레이밍

### 가장 낮은 축 팁 (WEAKEST_TIP)

| 축 | 팁 |
|----|-----|
| 요청력 | "AI에게 요청할 때 '배경 + 구체적 요청 + 원하는 형식'을 함께 알려주세요." |
| 검증력 | "AI 결과를 받으면 '이거 맞아?', '다른 방법은?' 하고 한 번 더 확인해보세요." |
| 활용력 | "Claude Code에는 다양한 기능이 있어요. /ax-eval 팁으로 새 기능을 알아보세요." |
| 판단력 | "'왜 이 방법인지', '다른 대안은 없는지' 물어보는 습관을 만들어보세요." |

---

## 오류 처리

- `~/ax-eval/config/profile.json` 없음: "먼저 `/ax-eval 시작`을 실행해주세요."
- convert_sessions.py 실행 실패: 기존 변환된 파일로 분석 진행 (경고 메시지 출력)
- `~/ax-eval/conversations/` 비어있음: 데이터 부족 처리로 분기
