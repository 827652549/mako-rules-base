#!/usr/bin/env bash
# Run from the target project root: bash ../mako-rules-base/scripts/init-project.sh
# Env vars (optional):
#   LINEAR_PROJECT    — Linear project name/slug for repo↔project mapping
#   CONTEXT7_API_KEY  — add context7 MCP if provided

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_BASE_REL="$(realpath --relative-to="$(pwd)" "$RULES_BASE" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE" "$(pwd)")"
PROJECT_PATH="$(pwd)"

echo "==> mako-rules-base: $RULES_BASE"
echo "==> 目标项目: $PROJECT_PATH"
echo ""

# 1. CLAUDE.md（base 自身跳过自引用）
IMPORT_LINE="@${RULES_BASE_REL}/CLAUDE.md"
if [ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ]; then
  echo "[1/7] base 自身，跳过 @import"
else
if [ ! -f CLAUDE.md ]; then
  echo "$IMPORT_LINE" > CLAUDE.md
  echo "[1/7] CLAUDE.md 已创建，写入 @import"
elif grep -qF "$IMPORT_LINE" CLAUDE.md; then
  echo "[1/7] CLAUDE.md 已包含 @import，跳过"
else
  echo "$IMPORT_LINE" | cat - CLAUDE.md > _tmp_claude && mv _tmp_claude CLAUDE.md
  echo "[1/7] CLAUDE.md 已在顶部插入 @import"
fi
fi

# 2. agents — 整目录 symlink（新增 agent 自动同步）
mkdir -p .claude
AGENTS_TARGET=".claude/agents"
AGENTS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/agents" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/agents" "$(pwd)/.claude")"
if [ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ]; then
  echo "[2/7] base 自身，跳过"
elif [ -L "$AGENTS_TARGET" ]; then
  echo "[2/7] agents 已是 symlink，跳过"
elif [ -d "$AGENTS_TARGET" ]; then
  rm -rf "$AGENTS_TARGET"
  ln -sf "$AGENTS_REL" "$AGENTS_TARGET"
  echo "[2/7] agents 已迁移为整目录 symlink"
else
  ln -sf "$AGENTS_REL" "$AGENTS_TARGET"
  echo "[2/7] agents -> 整目录 symlink 创建"
fi

# 3. skills — 整目录 symlink（新增 skill 自动同步）
mkdir -p .claude
SKILLS_TARGET=".claude/skills"
SKILLS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/skills" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/skills" "$(pwd)/.claude")"
if [ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ]; then
  echo "[3/7] base 自身，跳过"
elif [ -L "$SKILLS_TARGET" ]; then
  echo "[3/7] skills 已是 symlink，跳过"
elif [ -d "$SKILLS_TARGET" ]; then
  rm -rf "$SKILLS_TARGET"
  ln -sf "$SKILLS_REL" "$SKILLS_TARGET"
  echo "[3/7] skills 已迁移为整目录 symlink"
else
  ln -sf "$SKILLS_REL" "$SKILLS_TARGET"
  echo "[3/7] skills -> 整目录 symlink 创建"
fi

# 4. settings.local.json — symlink 共享权限配置
mkdir -p .claude
SETTINGS_TARGET=".claude/settings.local.json"
SETTINGS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/settings.local.json" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/settings.local.json" "$(pwd)/.claude")"
if [ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ]; then
  echo "[4/7] base 自身，跳过"
elif [ -L "$SETTINGS_TARGET" ]; then
  echo "[4/7] settings.local.json 已是 symlink，跳过"
elif [ -f "$SETTINGS_TARGET" ]; then
  mv "$SETTINGS_TARGET" "${SETTINGS_TARGET}.bak"
  ln -sf "$SETTINGS_REL" "$SETTINGS_TARGET"
  echo "[4/7] settings.local.json 已备份为 .bak 并替换为 symlink"
else
  ln -sf "$SETTINGS_REL" "$SETTINGS_TARGET"
  echo "[4/7] settings.local.json -> symlink 创建"
fi

# 5. Linear project 映射 — 写入 .claude/linear-project.json
LINEAR_MAPPING_FILE=".claude/linear-project.json"
if [ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ]; then
  echo "[5/7] base 自身，跳过"
elif [ -n "${LINEAR_PROJECT:-}" ]; then
  echo "{\"project\":\"$LINEAR_PROJECT\"}" > "$LINEAR_MAPPING_FILE"
  echo "[5/7] Linear project 映射已写入: $LINEAR_PROJECT"
elif [ -f "$LINEAR_MAPPING_FILE" ]; then
  echo "[5/7] linear-project.json 已存在，跳过"
else
  echo "[5/7] LINEAR_PROJECT 未设置，跳过（project-lead 运行时可自动匹配）"
fi

# 6. MCP servers — 写入 ~/.claude.json 的 projects.<path>.mcpServers
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
    print(f"[6/7] MCP 已添加: {', '.join(added)}")
if skipped:
    print(f"[6/7] MCP 已存在跳过: {', '.join(skipped)}")
if not context7_key:
    print("[6/7] context7 跳过 — 未设置 CONTEXT7_API_KEY（可 export 后重跑）")
PYEOF

# 7. 注册到 PROJECTS.md
PROJECTS_FILE="$RULES_BASE/PROJECTS.md"
TODAY="$(date +%Y-%m-%d)"
REPO_NAME="$(basename "$PROJECT_PATH")"
LINEAR_PROJ="${LINEAR_PROJECT:-$(cat "$PROJECT_PATH/.claude/linear-project.json" 2>/dev/null | python3 -c "import sys,json;print(json.load(sys.stdin).get('project',''))" 2>/dev/null || echo "")}"
if [ ! -f "$PROJECTS_FILE" ]; then
  cat > "$PROJECTS_FILE" << 'HEADER'
# 项目总览

各项目注册信息与关系说明。`init-project.sh` 自动维护注册部分，关系部分随手手动更新。

---

HEADER
fi
if grep -qF "$PROJECT_PATH" "$PROJECTS_FILE"; then
  echo "[7/7] PROJECTS.md 已包含本项目，跳过"
else
  cat >> "$PROJECTS_FILE" << EOF

## $REPO_NAME
- **路径**: $PROJECT_PATH
- **Linear**: ${LINEAR_PROJ:-待设置}
- **注册时间**: $TODAY
- **说明**: 待补充
- **关系**: 待补充

EOF
  echo "[7/7] 已注册到 PROJECTS.md"
fi

echo ""
echo "✓ 接入完成（重启 Claude Code 会话后 MCP 生效）"
