# iOS Simulator MCP 配置指南

> **适用范围**：仅适用于 iOS 原生项目，需要 PM Agent 验收模拟器 UI 时。

## 概述

iOS Simulator MCP 让 AI Agent 能通过 MCP 协议结构化控制 iOS Simulator：

| 工具 | 说明 | 依赖 idb_companion |
|------|------|:---:|
| `screenshot` | 截图保存到文件 | ❌ |
| `ui_view` | 截图返回 base64 | ❌ |
| `get_booted_sim_id` | 获取已启动模拟器 UUID | ❌ |
| `ui_describe_all` | UI 无障碍树（结构化文本） | ✅ |
| `ui_tap` | 模拟点击 | ✅ |
| `ui_swipe` | 模拟滑动 | ✅ |
| `ui_type` | 输入文本 | ✅ |
| `ui_find_element` | 搜索 UI 元素 | ✅ |
| `install_app` | 安装 .app/.ipa | ❌ |
| `launch_app` | 按 bundle ID 启动 app | ❌ |
| `record_video` | 录屏 | ❌ |

## 依赖组件

| 组件 | 版本 | 安装方式 | 用途 |
|------|------|----------|------|
| Node.js / npx | — | 系统已有 | MCP server 运行时 |
| ios-simulator-mcp | ≥1.6.0 | `npm install -g ios-simulator-mcp` | MCP server |
| idb (fb-idb) | ≥1.1.7 | `pipx install fb-idb` | UI 无障碍树（`ui_describe_all` 等） |
| idb_companion | ≥1.1.8 | GitHub releases 手动下载 | idb 的 gRPC daemon |

## 安装步骤

### 1. 安装 idb CLI

```bash
pipx install fb-idb
```

### 2. 安装 idb_companion + Frameworks

```bash
# 下载最新 release
cd /tmp
gh api repos/facebook/idb/releases/latest --jq '.assets[0].browser_download_url' \
  | xargs curl -sL -o idb-companion.tar.gz
tar xzf idb-companion.tar.gz

# 安装二进制
sudo cp idb-companion.universal/bin/idb_companion /usr/local/bin/

# 安装 Frameworks（idb_companion 运行依赖）
mkdir -p ~/Library/Frameworks
cp -R idb-companion.universal/Frameworks/* ~/Library/Frameworks/

# 清理
rm -rf idb-companion.tar.gz idb-companion.universal
```

### 3. 创建 idb wrapper

idb_companion 需要 `DYLD_FALLBACK_FRAMEWORK_PATH` 环境变量，且 idb 默认用 Unix socket 连接 companion（可能被拒绝）。wrapper 同时解决这两个问题：

```bash
cat > ~/.local/bin/idb << 'EOF'
#!/bin/bash
export DYLD_FALLBACK_FRAMEWORK_PATH=~/Library/Frameworks

# 自动检测 companion TCP 端口
COMPANION_PORT=""
for log in /tmp/idb_companion.log /tmp/idb_companion_*.log; do
  if [ -f "$log" ]; then
    COMPANION_PORT=$(grep -o '"grpc_port":[0-9]*' "$log" 2>/dev/null | head -1 | grep -o '[0-9]*$')
    if [ -n "$COMPANION_PORT" ]; then break; fi
  fi
done

# 优先 TCP 连接（比 Unix socket 更稳定）
IDB_ORIG="$(dirname "$0")/idb-original"
if [ -n "$COMPANION_PORT" ]; then
  exec "$IDB_ORIG" --companion "localhost:$COMPANION_PORT" "$@"
else
  exec "$IDB_ORIG" "$@"
fi
EOF
chmod +x ~/.local/bin/idb
```

> 注意：如果 `~/.local/bin/idb` 已被 pipx 安装了原版，先 `mv idb idb-original`。

### 4. 创建 companion 自动启动脚本

```bash
cat > /usr/local/bin/start-idb-companion << 'SCRIPT'
#!/bin/bash
export DYLD_FALLBACK_FRAMEWORK_PATH=~/Library/Frameworks

# 获取已启动模拟器 UUID
BOOTED_UDID=$(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted':
            print(d['udid']); sys.exit(0)
" 2>/dev/null)

[ -z "$BOOTED_UDID" ] && exit 1

# 检查 companion 是否存活（不只是看 state 文件）
if grep -q "$BOOTED_UDID" /tmp/idb/state 2>/dev/null; then
  PID=$(grep "$BOOTED_UDID" /tmp/idb/state | python3 -c "import sys,json;print(json.loads(sys.stdin.read())[0].get('pid',''))" 2>/dev/null)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    exit 0  # 已在运行
  fi
  rm -f /tmp/idb/state  # 进程已死，清理 stale state
fi

# 启动 companion
/usr/local/bin/idb_companion --udid "$BOOTED_UDID" > /tmp/idb_companion.log 2>&1 &
sleep 3
SCRIPT
chmod +x /usr/local/bin/start-idb-companion
```

### 5. 创建 MCP server wrapper

```bash
cat > /usr/local/bin/ios-simulator-mcp-wrapper << 'EOF'
#!/bin/bash
# 非阻塞启动 companion，MCP server 立即启动
/usr/local/bin/start-idb-companion 1>&2 &
exec ios-simulator-mcp "$@"
EOF
chmod +x /usr/local/bin/ios-simulator-mcp-wrapper
```

> 关键：companion 必须**非阻塞**启动（`&`），否则 MCP server 启动会超时（3s+ → Claude Code 拒绝连接）。

### 6. 注册到 Claude Code

```bash
claude mcp add ios-simulator -s user -- /usr/local/bin/ios-simulator-mcp-wrapper
```

同时写入 `~/.claude/settings.json`：

```json
{
  "mcpServers": {
    "ios-simulator": {
      "type": "stdio",
      "command": "/usr/local/bin/ios-simulator-mcp-wrapper",
      "args": [],
      "env": {
        "DYLD_FALLBACK_FRAMEWORK_PATH": "/Users/<用户名>/Library/Frameworks",
        "IOS_SIMULATOR_MCP_DEFAULT_OUTPUT_DIR": "/tmp/ios-simulator-mcp"
      }
    }
  }
}
```

### 7. 更新 Agent tools 白名单

在 `.claude/agents/<agent>.md` 的 frontmatter 中添加：

```yaml
tools:
  # ... existing tools ...
  - mcp__ios-simulator__get_booted_sim_id
  - mcp__ios-simulator__open_simulator
  - mcp__ios-simulator__screenshot
  - mcp__ios-simulator__ui_view
  - mcp__ios-simulator__ui_describe_all
  - mcp__ios-simulator__ui_describe_point
  - mcp__ios-simulator__ui_find_element
  - mcp__ios-simulator__ui_tap
  - mcp__ios-simulator__ui_swipe
  - mcp__ios-simulator__ui_type
  - mcp__ios-simulator__install_app
  - mcp__ios-simulator__launch_app
  - mcp__ios-simulator__record_video
  - mcp__ios-simulator__stop_recording
```

> **铁律**：agent 的 `tools:` 白名单决定了哪些 MCP 工具可用。不在此列表中的工具即使 MCP server 正常运行也无法调用。

## 健康检查

```bash
# 检查所有组件状态
bash scripts/check-ios-simulator-mcp.sh

# 自动修复可修复的问题
bash scripts/check-ios-simulator-mcp.sh --fix
```

## 已知陷阱

| 问题 | 原因 | 解决 |
|------|------|------|
| `ui_describe_all` 报 "Connection refused" | idb_companion 未运行 | wrapper 自动启动，或手动 `start-idb-companion` |
| `ui_describe_all` 报 "No such file: idb_companion" | Frameworks 未安装 | 安装到 `~/Library/Frameworks/` |
| MCP 工具在 agent 中不可用 | agent 白名单未添加 | 更新 `.claude/agents/*.md` |
| MCP server 启动超时 | wrapper 的 `sleep` 阻塞了 server | companion 改为非阻塞启动（`&`） |
| wrapper stdout 输出干扰 MCP 协议 | echo 输出到 stdout | 重定向到 stderr（`1>&2`） |
| companion state 文件 stale | 进程被 kill 但 state 未清理 | `start-idb-companion` 检查 PID 存活 |

## 文件清单

| 文件 | 说明 |
|------|------|
| `~/.local/bin/idb` | idb wrapper（DYLD + TCP companion） |
| `~/.local/bin/idb-original` | 原版 idb 备份 |
| `/usr/local/bin/idb_companion` | idb_companion 二进制 |
| `/usr/local/bin/start-idb-companion` | companion 管理脚本 |
| `/usr/local/bin/ios-simulator-mcp-wrapper` | MCP server 启动器 |
| `~/Library/Frameworks/FB*.framework` | idb_companion 依赖框架 |
| `~/.claude/settings.json` | Claude Code MCP 配置 |
| `.claude/agents/*.md` | Agent tools 白名单 |
