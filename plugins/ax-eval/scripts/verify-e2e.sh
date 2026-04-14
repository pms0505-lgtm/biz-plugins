#!/usr/bin/env bash
# verify-e2e.sh: ax-eval 플러그인 배포 전 자동 검증
# 사용: bash ~/Desktop/ax_eval/scripts/verify-e2e.sh
# 종료코드: 0=전체 통과, 1=실패 항목 있음

set -uo pipefail

PROJ="$HOME/Desktop/ax_eval"
CACHE="$HOME/.claude/plugins/cache/biz-plugins/ax-eval"
PASS=0
FAIL=0

green() { echo "  ✓ $*"; }
red()   { echo "  ✗ $*"; }

check() {
    local label="$1"; shift
    if "$@" &>/dev/null; then
        green "$label"
        PASS=$((PASS + 1))
    else
        red "$label"
        FAIL=$((FAIL + 1))
    fi
}

echo "━━━ ax-eval verify-e2e ━━━"
echo ""

# ── 1. Python 문법 ──────────────────────────────────────────
echo "[1] convert_sessions.py 문법"
check "py_compile 통과" python3 -m py_compile "$PROJ/scripts/convert_sessions.py"

# ── 2. 캐시 sync 상태 ───────────────────────────────────────
echo ""
echo "[2] 플러그인 캐시 sync 상태"

LATEST_VER=$(ls "$CACHE" 2>/dev/null | sort -V | tail -1)
if [ -z "$LATEST_VER" ]; then
    red "플러그인 캐시 없음: $CACHE"
    FAIL=$((FAIL + 1))
else
    DEST="$CACHE/$LATEST_VER"
    for skill in ax-eval ax-eval-check ax-eval-onboard ax-eval-tip; do
        check "$skill/SKILL.md 캐시 존재" test -f "$DEST/skills/$skill/SKILL.md"
    done

    # 소스 최신 여부 (캐시가 소스보다 오래된 경우 경고)
    for skill in ax-eval ax-eval-check ax-eval-onboard ax-eval-tip; do
        src="$PROJ/skills/$skill/SKILL.md"
        dst="$DEST/skills/$skill/SKILL.md"
        if [ -f "$src" ] && [ -f "$dst" ]; then
            if [ "$src" -nt "$dst" ]; then
                red "$skill 소스가 캐시보다 새로움 (sync 필요)"
                FAIL=$((FAIL + 1))
            else
                green "$skill 캐시 최신"
                PASS=$((PASS + 1))
            fi
        fi
    done
fi

# ── 3. Placeholder 잔류 체크 ────────────────────────────────
echo ""
echo "[3] {PLUGIN_SCRIPTS_DIR} placeholder 캐시 잔류"

if [ -n "${LATEST_VER:-}" ]; then
    DEST="$CACHE/$LATEST_VER"
    for skill in ax-eval-check ax-eval-onboard; do
        cache_file="$DEST/skills/$skill/SKILL.md"
        if [ -f "$cache_file" ]; then
            if grep -q '{PLUGIN_SCRIPTS_DIR}' "$cache_file"; then
                red "$skill 캐시에 placeholder 미치환"
                FAIL=$((FAIL + 1))
            else
                green "$skill placeholder 치환 완료"
                PASS=$((PASS + 1))
            fi
        fi
    done
fi

# ── 4. plugin.json 버전 vs git 태그 ─────────────────────────
echo ""
echo "[4] 버전 일관성"

PLUGIN_VER=$(grep '"version"' "$PROJ/.claude-plugin/plugin.json" 2>/dev/null \
    | grep -oP '[\d.]+')

LATEST_GIT_TAG=$(git -C "$PROJ" tag 2>/dev/null | sort -V | tail -1)
LATEST_CACHE_VER=$(ls "$CACHE" 2>/dev/null | sort -V | tail -1)

green "plugin.json 버전: v${PLUGIN_VER}"

if [ -n "$LATEST_GIT_TAG" ]; then
    if [ "v${PLUGIN_VER}" = "$LATEST_GIT_TAG" ] || [ "$PLUGIN_VER" = "$LATEST_GIT_TAG" ]; then
        green "plugin.json ↔ git tag 일치 ($LATEST_GIT_TAG)"
        PASS=$((PASS + 1))
    else
        red "plugin.json(v$PLUGIN_VER) ↔ git tag($LATEST_GIT_TAG) 불일치 — 배포 전 버전 bump 확인"
        FAIL=$((FAIL + 1))
    fi
else
    echo "  · git 태그 없음 (첫 배포 전)"
    PASS=$((PASS + 1))
fi

if [ -n "$LATEST_CACHE_VER" ] && [ "$PLUGIN_VER" != "$LATEST_CACHE_VER" ]; then
    red "plugin.json(v$PLUGIN_VER) ↔ 설치 캐시($LATEST_CACHE_VER) 불일치 — 재설치 필요"
    FAIL=$((FAIL + 1))
else
    [ -n "$LATEST_CACHE_VER" ] && green "plugin.json ↔ 설치 캐시 일치 ($LATEST_CACHE_VER)"
fi

# ── 5. ax-analyst.md 필수 반환 필드 ─────────────────────────
echo ""
echo "[5] ax-analyst.md 필수 반환 필드"

ANALYST="$PROJ/agents/ax-analyst.md"
for field in "LEVEL:" "LEVEL_NAME:" "COMPOSITE_SCORE:" "SCORES:" "WEAKEST_AXIS:" "HARNESS_UNUSED:"; do
    check "$field 정의됨" grep -q "$field" "$ANALYST"
done

# ── 결과 ────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  통과 $PASS  실패 $FAIL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━"

[ "$FAIL" -eq 0 ] && echo "  결과: PASS — 배포 가능" && exit 0
echo "  결과: FAIL — 위 항목 수정 후 재실행" && exit 1
