#!/bin/bash
# ax-nudge.sh — SessionStart 훅: 약한 축 자동 피드백 (주 1회)
# 배포용: 경로를 동적으로 탐지 (하드코딩 없음)

# Python/jq 동적 탐지
PYTHON=$(which python3 2>/dev/null || which python 2>/dev/null)
JQ=$(which jq 2>/dev/null)

ASSESS_DIR="$HOME/ax-eval/assessments"
STAMP="$HOME/ax-eval/.nudge-stamp"

# 1. assessment 없으면 조용히 종료
[ -d "$ASSESS_DIR" ] || exit 0
LATEST=$(ls -1 "$ASSESS_DIR"/assessment-*.json 2>/dev/null | sort -r | head -1)
[ -z "$LATEST" ] && exit 0

# 2. 쿨다운 체크 (7일)
if [ -f "$STAMP" ]; then
  STAMP_DATE=$(cat "$STAMP" 2>/dev/null)
  if [ -n "$STAMP_DATE" ] && [ -n "$PYTHON" ]; then
    DIFF_DAYS=$("$PYTHON" -c "
from datetime import date
try:
    d = date.fromisoformat('$STAMP_DATE')
    print((date.today() - d).days)
except:
    print(99)
" 2>/dev/null)
    [ -n "$DIFF_DAYS" ] && [ "$DIFF_DAYS" -lt 7 ] && exit 0
  fi
fi

# 3. JSON 파싱 (jq 있으면 jq, 없으면 Python으로 fallback)
if [ -n "$JQ" ]; then
  WEAKEST=$("$JQ" -r '.scores | to_entries | min_by(.value) | .key' "$LATEST" 2>/dev/null)
  WEAKEST_SCORE=$("$JQ" -r '.scores | to_entries | min_by(.value) | .value' "$LATEST" 2>/dev/null)
  LEVEL_NAME=$("$JQ" -r '.level_name' "$LATEST" 2>/dev/null)
  COMPOSITE=$("$JQ" -r '.composite' "$LATEST" 2>/dev/null)
  ASSESS_DATE=$("$JQ" -r '.date' "$LATEST" 2>/dev/null)
elif [ -n "$PYTHON" ]; then
  RESULT=$("$PYTHON" -c "
import json, sys
try:
    d = json.load(open('$LATEST'))
    scores = d.get('scores', {})
    weakest = min(scores, key=scores.get) if scores else ''
    print(weakest)
    print(scores.get(weakest, ''))
    print(d.get('level_name', ''))
    print(d.get('composite', ''))
    print(d.get('date', ''))
except:
    pass
" 2>/dev/null)
  WEAKEST=$(echo "$RESULT" | sed -n '1p')
  WEAKEST_SCORE=$(echo "$RESULT" | sed -n '2p')
  LEVEL_NAME=$(echo "$RESULT" | sed -n '3p')
  COMPOSITE=$(echo "$RESULT" | sed -n '4p')
  ASSESS_DATE=$(echo "$RESULT" | sed -n '5p')
else
  exit 0
fi

[ -z "$WEAKEST" ] && exit 0

# 4. 축별 팁 매핑
case "$WEAKEST" in
  "요청력") TIP="AI에게 요청할 때 배경 + 구체적 요청 + 원하는 형식을 함께 알려주세요." ;;
  "검증력") TIP="AI 결과를 받으면 이거 맞아? 다른 방법은? 하고 한 번 더 확인해보세요." ;;
  "활용력") TIP="Claude Code에는 다양한 기능이 있어요. /ax-eval 팁으로 새 기능을 알아보세요." ;;
  "판단력") TIP="왜 이 방법인지, 다른 대안은 없는지 물어보는 습관을 만들어보세요." ;;
  *) exit 0 ;;
esac

# 5. staleness 체크 (14일 이상이면 체크 권유)
STALE_MSG=""
if [ -n "$ASSESS_DATE" ] && [ -n "$PYTHON" ]; then
  STALE_DAYS=$("$PYTHON" -c "
from datetime import date
try:
    d = date.fromisoformat('$ASSESS_DATE')
    print((date.today() - d).days)
except:
    print(0)
" 2>/dev/null)
  if [ -n "$STALE_DAYS" ] && [ "$STALE_DAYS" -ge 14 ]; then
    STALE_MSG=" (마지막 평가가 ${STALE_DAYS}일 전입니다. /ax-eval 체크로 최신 상태를 확인해보세요!)"
  fi
fi

# 6. stamp 갱신
date +%Y-%m-%d > "$STAMP" 2>/dev/null

# 7. systemMessage 출력
MSG="[AX-Eval] 현재 레벨: ${LEVEL_NAME} (종합 ${COMPOSITE}점). 가장 성장 여지가 큰 축: ${WEAKEST} (${WEAKEST_SCORE}점). ${TIP}${STALE_MSG}"
printf '{"systemMessage": "%s"}' "$MSG"
