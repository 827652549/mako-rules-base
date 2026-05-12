#!/usr/bin/env bash
# Run from the target project root: bash ../mako-rules-base/scripts/init-project.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_BASE_REL="$(realpath --relative-to="$(pwd)" "$RULES_BASE" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE" "$(pwd)")"

echo "==> mako-rules-base: $RULES_BASE"
echo "==> 目标项目: $(pwd)"
echo ""

# 1. CLAUDE.md
IMPORT_LINE="@${RULES_BASE_REL}/CLAUDE.md"
if [ ! -f CLAUDE.md ]; then
  echo "$IMPORT_LINE" > CLAUDE.md
  echo "[1/3] CLAUDE.md 已创建，写入 @import"
elif grep -qF "$IMPORT_LINE" CLAUDE.md; then
  echo "[1/3] CLAUDE.md 已包含 @import，跳过"
else
  echo "$IMPORT_LINE" | cat - CLAUDE.md > _tmp_claude && mv _tmp_claude CLAUDE.md
  echo "[1/3] CLAUDE.md 已在顶部插入 @import"
fi

# 2. agents symlinks
mkdir -p .claude/agents
AGENTS_REL="$(realpath --relative-to="$(pwd)/.claude/agents" "$RULES_BASE/claude/agents" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/claude/agents" "$(pwd)/.claude/agents")"
for agent in "$RULES_BASE/claude/agents/"*.md; do
  name="$(basename "$agent")"
  target=".claude/agents/$name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "[2/3] agent $name 已存在，跳过"
  else
    ln -sf "$AGENTS_REL/$name" "$target"
    echo "[2/3] agent $name -> symlink 创建"
  fi
done

# 3. skills symlinks
mkdir -p .claude/skills
SKILLS_REL="$(realpath --relative-to="$(pwd)/.claude/skills" "$RULES_BASE/claude/skills" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/claude/skills" "$(pwd)/.claude/skills")"
for skill in "$RULES_BASE/claude/skills/"/*/; do
  name="$(basename "$skill")"
  target=".claude/skills/$name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "[3/3] skill $name 已存在，跳过"
  else
    ln -sf "$SKILLS_REL/$name" "$target"
    echo "[3/3] skill $name -> symlink 创建"
  fi
done

echo ""
echo "✓ 接入完成"
