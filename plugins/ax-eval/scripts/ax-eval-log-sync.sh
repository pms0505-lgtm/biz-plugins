#!/bin/bash
# ax-eval-log-sync.sh — Stop 훅: 세션 종료 시 대화 로그 자동 변환
# 배포용: 경로를 동적으로 탐지 (하드코딩 없음)

PYTHON=$(which python3 2>/dev/null || which python 2>/dev/null)
CONFIG="$HOME/ax-eval/config/profile.json"
OUTPUT_DIR="$HOME/ax-eval/conversations"
NAMES_FILE="$HOME/ax-eval/config/project_names.json"

# Python 없거나 온보딩 전이면 조용히 종료
[ -n "$PYTHON" ] || exit 0
[ -f "$CONFIG" ] || exit 0

# convert_sessions.py 경로 탐색 (플러그인 캐시 → CLAUDE_PLUGIN_ROOT → 개발 경로)
if [ -n "$CLAUDE_PLUGIN_ROOT" ] && [ -f "$CLAUDE_PLUGIN_ROOT/scripts/convert_sessions.py" ]; then
  SCRIPT="$CLAUDE_PLUGIN_ROOT/scripts/convert_sessions.py"
else
  SCRIPT=$(find "$HOME/.claude/plugins" -name "convert_sessions.py" -path "*/ax-eval/*" 2>/dev/null | head -1)
fi

[ -z "$SCRIPT" ] && exit 0

# 백그라운드로 실행 (Stop 훅 타임아웃 방지)
"$PYTHON" "$SCRIPT" --output-dir "$OUTPUT_DIR" --names-file "$NAMES_FILE" &>/dev/null &
exit 0
