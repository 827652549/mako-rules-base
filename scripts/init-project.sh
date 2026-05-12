#!/usr/bin/env bash
# Run from the target project root: bash ../mako-rules-base/scripts/init-project.sh
# Env vars (optional):
#   CONTEXT7_API_KEY  — add context7 MCP if provided

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_BASE_REL="$(realpath --relative-to="$(pwd)" "$RULES_BASE" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE" "$(pwd)")"
PROJECT_PATH="$(pwd)"

echo "==> mako-rules-base: $RULES_BASE"
echo "==> 目标项目: $PROJECT_PATH"
echo ""

# 1. CLAUDE.md
IMPORT_LINE="@${RULES_BASE_REL}/CLAUDE.md"
if [ ! -f CLAUDE.md ]; then
  echo "$IMPORT_LINE" > CLAUDE.md
  echo "[1/4] CLAUDE.md 已创建，写入 @import"
elif grep -qF "$IMPORT_LINE" CLAUDE.md; then
  echo "[1/4] CLAUDE.md 已包含 @import，跳过"
else
  echo "$IMPORT_LINE" | cat - CLAUDE.md > _tmp_claude && mv _tmp_claude CLAUDE.md
  echo "[1/4] CLAUDE.md 已在顶部插入 @import"
fi

# 2. agents symlinks
mkdir -p .claude/agents
AGENTS_REL="$(realpath --relative-to="$(pwd)/.claude/agents" "$RULES_BASE/claude/agents" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/claude/agents" "$(pwd)/.claude/agents")"
for agent in "$RULES_BASE/claude/agents/"*.md; do
  name="$(basename "$agent")"
  target=".claude/agents/$name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "[2/4] agent $name 已存在，跳过"
  else
    ln -sf "$AGENTS_REL/$name" "$target"
    echo "[2/4] agent $name -> symlink 创建"
  fi
done

# 3. skills symlinks
mkdir -p .claude/skills
SKILLS_REL="$(realpath --relative-to="$(pwd)/.claude/skills" "$RULES_BASE/claude/skills" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/claude/skills" "$(pwd)/.claude/skills")"
for skill in "$RULES_BASE/claude/skills/"/*/; do
  name="$(basename "$skill")"
  target=".claude/skills/$name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    echo "[3/4] skill $name 已存在，跳过"
  else
    ln -sf "$SKILLS_REL/$name" "$target"
    echo "[3/4] skill $name -> symlink 创建"
  fi
done

# 4. MCP servers — 写入 ~/.claude.json 的 projects.<path>.mcpServers
#    - linear        : OAuth HTTP MCP，无需 key
#    - vercel        : OAuth HTTP MCP，无需 key
#    - chrome-devtools: stdio MCP，无需 key
#    - context7      : HTTP MCP，需 CONTEXT7_API_KEY 环境变量
python3 - "$PROJECT_PATH" "${CONTEXT7_API_KEY:-}" << 'PYEOF'
import json, sys, os

project_path = sys.argv[1]
context7_key = sys.argv[2]
claude_json_path = os.path.expanduser("~/.claude.json")

base_servers = {
    "linear": {"type": "http", "url": "https://mcp.linear.app/mcp"},
    "vercel": {"type": "http", "url": "https://mcp.vercel.com"},
    "chrome-devtools": {
        "type": "stdio",
        "command": "npx",
        "args": ["chrome-devtools-mcp@latest"],
        "env": {},
    },
}

if context7_key:
    base_servers["context7"] = {
        "type": "http",
        "url": "https://mcp.context7.com/mcp",
        "headers": {"CONTEXT7_API_KEY": context7_key},
    }

with open(claude_json_path, "r", encoding="utf-8") as f:
    data = json.load(f)

projects = data.setdefault("projects", {})
project  = projects.setdefault(project_path, {})
mcp      = project.setdefault("mcpServers", {})

added, skipped = [], []
for name, cfg in base_servers.items():
    if name in mcp:
        skipped.append(name)
    else:
        mcp[name] = cfg
        added.append(name)

with open(claude_json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, separators=(",", ":"))

if added:
    print(f"[4/4] MCP 已添加: {', '.join(added)}")
if skipped:
    print(f"[4/4] MCP 已存在跳过: {', '.join(skipped)}")
if not context7_key:
    print("[4/4] context7 跳过 — 未设置 CONTEXT7_API_KEY（可 export 后重跑）")
PYEOF

echo ""
echo "✓ 接入完成（重启 Claude Code 会话后 MCP 生效）"
