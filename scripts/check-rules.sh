#!/usr/bin/env bash
# Check that every rules/*.md file is referenced in the corresponding entry point.
# Usage: bash scripts/check-rules.sh [RULES_BASE_PATH]
#   RULES_BASE_PATH defaults to the directory containing this script's parent.
#
# Exit codes:
#   0 — all files are imported, nothing missing
#   1 — one or more files are not imported

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_BASE="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"

CLAUDE_MD="$RULES_BASE/CLAUDE.md"
RULES_DIR="$RULES_BASE/rules"

MISSING=0

# ── Helper ────────────────────────────────────────────────────────────────────
check_file() {
  local file="$1"        # absolute path to the .md file
  local entry="$2"       # absolute path to the entry-point file that should @import it
  local rel="$3"         # the @import line to look for (relative to RULES_BASE)

  if ! grep -qF "@${rel}" "$entry" 2>/dev/null; then
    echo "  ✗ 未引用: rules/${rel}"
    echo "    → 应加入: $(basename "$entry")"
    MISSING=$((MISSING + 1))
  fi
}

echo "==> 检查 rules 引用完整性：$RULES_BASE"
echo ""

# ── 1. rules/base/*.md → CLAUDE.md ──────────────────────────────────────────
echo "[base] 检查 CLAUDE.md..."
BASE_ISSUES=0
for f in "$RULES_DIR/base/"*.md; do
  [ -f "$f" ] || continue
  fname="$(basename "$f")"
  rel="base/$fname"
  if ! grep -qF "@rules/$rel" "$CLAUDE_MD" 2>/dev/null; then
    echo "  ✗ 未引用: rules/$rel"
    echo "    → 应加入: CLAUDE.md"
    MISSING=$((MISSING + 1))
    BASE_ISSUES=$((BASE_ISSUES + 1))
  fi
done
[ "$BASE_ISSUES" -eq 0 ] && echo "  ✓ 全部已引用"
echo ""

# ── 2. rules/{platform}/*.md → rules/{platform}-platform.md ─────────────────
for platform in nextjs ios expo python; do
  platform_dir="$RULES_DIR/$platform"
  platform_entry="$RULES_DIR/${platform}-platform.md"

  [ -d "$platform_dir" ] || continue

  echo "[$platform] 检查 ${platform}-platform.md..."
  PLAT_ISSUES=0

  for f in "$platform_dir/"*.md; do
    [ -f "$f" ] || continue
    fname="$(basename "$f")"
    rel="${platform}/$fname"
    if ! grep -qF "@rules/$rel" "$platform_entry" 2>/dev/null; then
      echo "  ✗ 未引用: rules/$rel"
      echo "    → 应加入: ${platform}-platform.md"
      MISSING=$((MISSING + 1))
      PLAT_ISSUES=$((PLAT_ISSUES + 1))
    fi
  done

  [ "$PLAT_ISSUES" -eq 0 ] && echo "  ✓ 全部已引用"
  echo ""
done

# ── 结果 ──────────────────────────────────────────────────────────────────────
if [ "$MISSING" -eq 0 ]; then
  echo "✓ 检查通过，所有规则文件均已挂载。"
  exit 0
else
  echo "✗ 发现 $MISSING 个未挂载的规则文件，请补充 @import。"
  exit 1
fi
