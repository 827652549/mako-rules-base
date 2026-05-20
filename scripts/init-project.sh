#!/usr/bin/env bash
# Run from the target project root: bash ../mako-rules-base/scripts/init-project.sh
# Env vars (optional):
#   CONTEXT7_API_KEY  — add context7 MCP if provided
#   PLATFORM          — skip interactive prompt: nextjs | ios | expo | python | base
#   GH_VISIBILITY     — public | private (default: private)，跳过 GitHub 创建询问

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_BASE_REL="$(realpath --relative-to="$(pwd)" "$RULES_BASE" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE" "$(pwd)")"
PROJECT_PATH="$(pwd)"
IS_BASE_SELF="$([ "$(realpath "$PROJECT_PATH" 2>/dev/null || echo "$PROJECT_PATH")" = "$(realpath "$RULES_BASE" 2>/dev/null || echo "$RULES_BASE")" ] && echo "yes" || echo "no")"

echo "==> mako-rules-base: $RULES_BASE"
echo "==> 目标项目: $PROJECT_PATH"
echo ""

# ── 步骤 0：Git 初始化 ────────────────────────────────────────────────────
if [ ! -d .git ]; then
  echo "[0/7] 未检测到 git 仓库，开始初始化..."
  git init

  # 提交一个空 commit 以确保分支存在，再重命名为 release
  INIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
  git commit --allow-empty -m "chore: init"
  git branch -m "$INIT_BRANCH" release
  echo "[0/7] git 已初始化，主分支：release"

  # 若 gh 可用且尚无 remote，询问是否创建 GitHub 仓库
  REPO_NAME="$(basename "$PROJECT_PATH")"
  if command -v gh &>/dev/null && ! git remote get-url origin &>/dev/null; then
    if [ -n "${GH_VISIBILITY:-}" ]; then
      # 环境变量指定，不交互
      VIS="$GH_VISIBILITY"
    else
      read -r -p "[0/7] 是否创建 GitHub 远端仓库？[y/N] " yn
      if [[ "$yn" =~ ^[Yy]$ ]]; then
        read -r -p "[0/7] 可见性 (public/private) [private]: " VIS
        VIS="${VIS:-private}"
      else
        VIS=""
      fi
    fi

    if [ -n "$VIS" ]; then
      gh repo create "$REPO_NAME" --"$VIS" --source=. --remote=origin --push
      # 将 GitHub 默认分支设为 release（origin 上此时只有 release）
      gh repo edit --default-branch release 2>/dev/null || true
      echo "[0/7] GitHub 仓库已创建并推送：$REPO_NAME（$VIS）"
    else
      echo "[0/7] 跳过 GitHub 创建。手动推送："
      echo "       gh repo create $REPO_NAME --private --source=. --remote=origin --push"
    fi
  fi
else
  echo "[0/7] 已有 git 仓库，跳过初始化"
fi
echo ""

# ── 平台选择 ────────────────────────────────────────────────────────────────
VALID_PLATFORMS="nextjs ios expo python base"

select_platform() {
  echo "请选择项目平台："
  echo "  1) nextjs  — Next.js App Router（Vercel 部署）"
  echo "  2) ios     — iOS 原生项目（Swift / SwiftUI）"
  echo "  3) expo    — Expo / React Native"
  echo "  4) python  — Python 后端（FastAPI）"
  echo "  5) base    — 仅通用规范（无平台专属）"
  echo ""
  read -r -p "请输入编号 [1-5]: " choice
  case "$choice" in
    1) echo "nextjs" ;;
    2) echo "ios" ;;
    3) echo "expo" ;;
    4) echo "python" ;;
    5) echo "base" ;;
    *)
      echo "无效选项，请重新选择" >&2
      select_platform
      ;;
  esac
}

if [ "$IS_BASE_SELF" = "yes" ]; then
  PLATFORM="base"
elif [ -n "${PLATFORM:-}" ]; then
  # 环境变量传入，校验合法性
  if ! echo "$VALID_PLATFORMS" | grep -qw "$PLATFORM"; then
    echo "错误：PLATFORM='$PLATFORM' 无效，合法值：$VALID_PLATFORMS" >&2
    exit 1
  fi
  echo "[platform] 使用环境变量指定的平台：$PLATFORM"
else
  PLATFORM="$(select_platform)"
fi
echo ""
echo "==> 平台：$PLATFORM"
echo ""

# ── 步骤 1：CLAUDE.md @import ─────────────────────────────────────────────
BASE_IMPORT_LINE="@${RULES_BASE_REL}/CLAUDE.md"
PLATFORM_IMPORT_LINE=""
[ "$PLATFORM" != "base" ] && PLATFORM_IMPORT_LINE="@${RULES_BASE_REL}/rules/${PLATFORM}-platform.md"

if [ "$IS_BASE_SELF" = "yes" ]; then
  echo "[1/7] base 自身，跳过 @import"
else
  # 创建或追加 base import
  if [ ! -f CLAUDE.md ]; then
    {
      echo "$BASE_IMPORT_LINE"
      [ -n "$PLATFORM_IMPORT_LINE" ] && echo "$PLATFORM_IMPORT_LINE"
    } > CLAUDE.md
    echo "[1/7] CLAUDE.md 已创建，写入 @import（base + $PLATFORM）"
  else
    CHANGED=0
    if grep -qF "$BASE_IMPORT_LINE" CLAUDE.md; then
      echo "[1/7] CLAUDE.md 已包含 base @import，跳过"
    else
      echo "$BASE_IMPORT_LINE" | cat - CLAUDE.md > _tmp_claude && mv _tmp_claude CLAUDE.md
      CHANGED=1
      echo "[1/7] CLAUDE.md 已在顶部插入 base @import"
    fi
    if [ -n "$PLATFORM_IMPORT_LINE" ]; then
      if grep -qF "$PLATFORM_IMPORT_LINE" CLAUDE.md; then
        echo "[1/7] CLAUDE.md 已包含 $PLATFORM @import，跳过"
      else
        # 插入到 base import 行之后
        sed -i.bak "/${BASE_IMPORT_LINE//\//\\/}/a\\
${PLATFORM_IMPORT_LINE}" CLAUDE.md && rm -f CLAUDE.md.bak
        CHANGED=1
        echo "[1/7] CLAUDE.md 已插入 $PLATFORM 平台 @import"
      fi
    fi
  fi
fi

# ── 步骤 2：agents symlink ────────────────────────────────────────────────
mkdir -p .claude
AGENTS_TARGET=".claude/agents"
AGENTS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/agents" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/agents" "$(pwd)/.claude")"
if [ "$IS_BASE_SELF" = "yes" ]; then
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

# ── 步骤 3：skills symlink ────────────────────────────────────────────────
SKILLS_TARGET=".claude/skills"
SKILLS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/skills" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/skills" "$(pwd)/.claude")"
if [ "$IS_BASE_SELF" = "yes" ]; then
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

# ── 步骤 4：settings.local.json symlink ──────────────────────────────────
SETTINGS_TARGET=".claude/settings.local.json"
SETTINGS_REL="$(realpath --relative-to="$(pwd)/.claude" "$RULES_BASE/.claude/settings.local.json" 2>/dev/null || python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))" "$RULES_BASE/.claude/settings.local.json" "$(pwd)/.claude")"
if [ "$IS_BASE_SELF" = "yes" ]; then
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

# ── 步骤 5：MCP servers ───────────────────────────────────────────────────
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
    print(f"[5/7] MCP 已添加: {', '.join(added)}")
if skipped:
    print(f"[5/7] MCP 已存在跳过: {', '.join(skipped)}")
if not context7_key:
    print("[5/7] context7 跳过 — 未设置 CONTEXT7_API_KEY（可 export 后重跑）")
PYEOF

# ── 步骤 6：注册到 PROJECTS.md ───────────────────────────────────────────
PROJECTS_FILE="$RULES_BASE/PROJECTS.md"
TODAY="$(date +%Y-%m-%d)"
REPO_NAME="$(basename "$PROJECT_PATH")"
if [ ! -f "$PROJECTS_FILE" ]; then
  cat > "$PROJECTS_FILE" << 'HEADER'
# 项目总览

各项目注册信息与关系说明。`init-project.sh` 自动维护注册部分，关系部分随手手动更新。

---

HEADER
fi
if grep -qF "$PROJECT_PATH" "$PROJECTS_FILE"; then
  echo "[6/7] PROJECTS.md 已包含本项目，跳过"
else
  cat >> "$PROJECTS_FILE" << EOF

## $REPO_NAME
- **路径**: $PROJECT_PATH
- **平台**: $PLATFORM
- **Linear**: 待设置
- **注册时间**: $TODAY
- **说明**: 待补充
- **关系**: 待补充

EOF
  echo "[6/7] 已注册到 PROJECTS.md"
fi

# ── 步骤 7：注册到 clp-mapping.json ──────────────────────────────────────
CLP_MAPPING="$HOME/.claude/clp-mapping.json"
python3 - "$REPO_NAME" "$PROJECT_PATH" "$CLP_MAPPING" << 'PYEOF'
import json, sys, os

repo_name, project_path, mapping_file = sys.argv[1], sys.argv[2], sys.argv[3]

if os.path.exists(mapping_file):
    with open(mapping_file, "r") as f:
        mapping = json.load(f)
else:
    mapping = {}

if mapping.get(repo_name) == project_path:
    print(f"[7/7] clp-mapping.json 已包含 {repo_name}，跳过")
else:
    mapping[repo_name] = project_path
    os.makedirs(os.path.dirname(mapping_file), exist_ok=True)
    with open(mapping_file, "w") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print(f"[7/7] clp-mapping.json 已更新: {repo_name} → {project_path}")
PYEOF

echo ""
echo "✓ 接入完成（重启 Claude Code 会话后 MCP 生效）"
echo ""
echo "  已写入 CLAUDE.md："
echo "    base  : @${RULES_BASE_REL}/CLAUDE.md"
[ -n "$PLATFORM_IMPORT_LINE" ] && echo "    $PLATFORM : $PLATFORM_IMPORT_LINE"
echo ""
echo "  迁移现有子项目："
echo "    cd <project> && PLATFORM=${PLATFORM} bash ${RULES_BASE_REL}/scripts/init-project.sh"
