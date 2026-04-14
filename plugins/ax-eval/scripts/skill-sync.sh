#!/usr/bin/env bash
# skill-sync.sh: SKILL.md 수정 감지 → 플러그인 캐시 자동 동기화
# PostToolUse(Write|Edit) 훅에서 stdin으로 tool input JSON을 받아 실행

set -euo pipefail

PROJ="$HOME/Desktop/ax_eval"
CACHE="$HOME/.claude/plugins/cache/biz-plugins/ax-eval"
SCRIPTS_DIR="$PROJ/scripts"

# 최신 버전 캐시 경로 결정
LATEST_VER=$(ls "$CACHE" 2>/dev/null | sort -V | tail -1)
if [ -z "$LATEST_VER" ]; then
    echo "[skill-sync] 플러그인 캐시 없음: $CACHE" >&2
    exit 0
fi
DEST="$CACHE/$LATEST_VER"

sync_skill() {
    local skill="$1"
    mkdir -p "$DEST/skills/$skill"
    if [[ "$skill" == "ax-eval-check" || "$skill" == "ax-eval-onboard" ]]; then
        sed "s|{PLUGIN_SCRIPTS_DIR}|$SCRIPTS_DIR|g" \
            "$PROJ/skills/$skill/SKILL.md" > "$DEST/skills/$skill/SKILL.md"
    else
        cp "$PROJ/skills/$skill/SKILL.md" "$DEST/skills/$skill/SKILL.md"
    fi
    echo "[skill-sync] ✓ $skill → $DEST/skills/$skill/SKILL.md"
}

# --all: 전체 스킬 동기화 (수동 실행 시)
if [ "${1:-}" = "--all" ]; then
    echo "[skill-sync] 전체 sync 시작..."
    for s in ax-eval ax-eval-check ax-eval-onboard ax-eval-tip; do
        sync_skill "$s"
    done
    echo "[skill-sync] 완료. Claude Code 재시작 시 반영됩니다."
    exit 0
fi

# PostToolUse 훅 모드: stdin JSON에서 file_path 추출
CHANGED_FILE=$(python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# skills/ 하위 SKILL.md가 아니면 스킵
if ! echo "$CHANGED_FILE" | grep -q "ax_eval/skills/"; then
    exit 0
fi

# 변경된 스킬 이름 추출
SKILL=$(basename "$(dirname "$CHANGED_FILE")")
if [ -z "$SKILL" ] || [ "$SKILL" = "skills" ]; then
    echo "[skill-sync] 스킬 이름 추출 실패: $CHANGED_FILE" >&2
    exit 0
fi

sync_skill "$SKILL"
echo "[skill-sync] Claude Code 재시작 시 반영됩니다."
