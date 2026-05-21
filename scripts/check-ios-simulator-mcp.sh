#!/bin/bash
# iOS Simulator MCP 健康检查 & 自动修复
# 用法: bash check-ios-simulator-mcp.sh [--fix]
#
# 检查项:
#   1. npx / Node.js
#   2. idb CLI (Facebook iOS Development Bridge)
#   3. idb_companion binary + Frameworks
#   4. ios-simulator-mcp (npm package)
#   5. Claude Code MCP 配置 (~/.claude/settings.json)
#   6. idb wrapper (DYLD + TCP companion)
#   7. idb_companion 进程状态
#   8. iOS Simulator 状态
#
# --fix: 自动修复可修复的问题

set -euo pipefail

FIX_MODE=false
[[ "${1:-}" == "--fix" ]] && FIX_MODE=true

PASS="✅"
FAIL="❌"
WARN="⚠️"
FIXED="🔧"
results=()

check() {
  local name="$1" status="$2" detail="$3"
  results+=("$status $name: $detail")
  echo "$status $name: $detail"
}

# ─── 1. Node.js / npx ───
if command -v npx &>/dev/null; then
  check "Node.js/npx" "$PASS" "$(npx --version 2>&1 | head -1)"
else
  check "Node.js/npx" "$FAIL" "npx not found — install Node.js"
fi

# ─── 2. idb CLI ───
IDB_BIN=""
if command -v idb &>/dev/null; then
  IDB_BIN="$(which idb)"
  # Check if it's our wrapper or the original
  if grep -q "DYLD_FALLBACK_FRAMEWORK_PATH" "$IDB_BIN" 2>/dev/null; then
    check "idb CLI" "$PASS" "$IDB_BIN (wrapper with DYLD)"
  else
    check "idb CLI" "$WARN" "$IDB_BIN (original, no DYLD wrapper)"
    if $FIX_MODE; then
      echo "  $FIXED idb wrapper 未安装，需手动配置（见 rules/ios/simulator-mcp.md）"
    fi
  fi
else
  check "idb CLI" "$FAIL" "not found"
  if $FIX_MODE; then
    echo "  $FIXED 安装 idb..."
    pipx install fb-idb 2>/dev/null && echo "  $FIXED idb installed via pipx" || echo "  $FAIL pipx install failed"
  fi
fi

# ─── 3. idb_companion ───
if command -v idb_companion &>/dev/null; then
  COMPANION_PATH="$(which idb_companion)"
  check "idb_companion" "$PASS" "$COMPANION_PATH"
else
  check "idb_companion" "$FAIL" "not found at /usr/local/bin/idb_companion"
  if $FIX_MODE; then
    echo "  $FIXED 下载 idb_companion v1.1.8..."
    cd /tmp
    DOWNLOAD_URL=$(gh api repos/facebook/idb/releases/latest --jq '.assets[0].browser_download_url' 2>/dev/null)
    if [ -n "$DOWNLOAD_URL" ]; then
      curl -sL -o idb-companion.tar.gz "$DOWNLOAD_URL"
      tar xzf idb-companion.tar.gz
      sudo cp idb-companion.universal/bin/idb_companion /usr/local/bin/
      mkdir -p ~/Library/Frameworks
      cp -R idb-companion.universal/Frameworks/* ~/Library/Frameworks/
      rm -rf idb-companion.tar.gz idb-companion.universal
      echo "  $FIXED idb_companion + Frameworks installed"
    else
      echo "  $FAIL 无法获取 download URL"
    fi
  fi
fi

# Check Frameworks
if [ -d ~/Library/Frameworks/FBControlCore.framework ]; then
  check "idb Frameworks" "$PASS" "~/Library/Frameworks/"
else
  check "idb Frameworks" "$FAIL" "FBControlCore.framework not found in ~/Library/Frameworks/"
fi

# ─── 4. ios-simulator-mcp ───
MCP_BIN=""
if command -v ios-simulator-mcp &>/dev/null; then
  MCP_BIN="$(which ios-simulator-mcp)"
  check "ios-simulator-mcp" "$PASS" "$MCP_BIN"
elif npx -y ios-simulator-mcp --help &>/dev/null 2>&1; then
  check "ios-simulator-mcp" "$WARN" "available via npx (not installed globally)"
  if $FIX_MODE; then
    echo "  $FIXED 全局安装 ios-simulator-mcp..."
    npm install -g ios-simulator-mcp 2>/dev/null && echo "  $FIXED installed globally" || echo "  $FAIL npm install failed"
    MCP_BIN="$(npm root -g)/ios-simulator-mcp/build/index.js" 2>/dev/null
  fi
else
  check "ios-simulator-mcp" "$FAIL" "not found"
  if $FIX_MODE; then
    echo "  $FIXED 安装 ios-simulator-mcp..."
    npm install -g ios-simulator-mcp 2>/dev/null && echo "  $FIXED installed" || echo "  $FAIL install failed"
  fi
fi

# ─── 5. Claude Code MCP 配置 ───
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  HAS_MCP=$(python3 -c "
import json
with open('$SETTINGS_FILE') as f:
    d = json.load(f)
ms = d.get('mcpServers', {})
print('yes' if 'ios-simulator' in ms else 'no')
" 2>/dev/null)
  if [ "$HAS_MCP" = "yes" ]; then
    check "MCP config (settings.json)" "$PASS" "ios-simulator configured"
  else
    check "MCP config (settings.json)" "$FAIL" "ios-simulator not in mcpServers"
    if $FIX_MODE; then
      echo "  $FIXED 添加 ios-simulator MCP 配置..."
      python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    s = json.load(f)
if 'mcpServers' not in s:
    s['mcpServers'] = {}
s['mcpServers']['ios-simulator'] = {
    'type': 'stdio',
    'command': '/usr/local/bin/ios-simulator-mcp-wrapper',
    'args': [],
    'env': {
        'DYLD_FALLBACK_FRAMEWORK_PATH': '$HOME/Library/Frameworks',
        'IOS_SIMULATOR_MCP_DEFAULT_OUTPUT_DIR': '/tmp/ios-simulator-mcp'
    }
}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(s, f, indent=2)
print('  $FIXED Config written to $SETTINGS_FILE')
"
    fi
  fi
else
  check "MCP config (settings.json)" "$FAIL" "settings.json not found"
fi

# ─── 6. idb wrapper ───
IDB_WRAPPER="$HOME/.local/bin/idb"
if [ -f "$IDB_WRAPPER" ] && head -1 "$IDB_WRAPPER" 2>/dev/null | grep -q "#!/bin/bash"; then
  if grep -q "DYLD_FALLBACK_FRAMEWORK_PATH" "$IDB_WRAPPER" 2>/dev/null; then
    check "idb wrapper" "$PASS" "$IDB_WRAPPER"
  else
    check "idb wrapper" "$WARN" "exists but missing DYLD config"
  fi
else
  check "idb wrapper" "$FAIL" "not found at $IDB_WRAPPER"
fi

# MCP server wrapper
MCP_WRAPPER="/usr/local/bin/ios-simulator-mcp-wrapper"
if [ -f "$MCP_WRAPPER" ]; then
  if grep -q "ios-simulator-mcp" "$MCP_WRAPPER" 2>/dev/null; then
    check "MCP wrapper" "$PASS" "$MCP_WRAPPER"
  else
    check "MCP wrapper" "$WARN" "exists but may be misconfigured"
  fi
else
  check "MCP wrapper" "$FAIL" "not found at $MCP_WRAPPER"
fi

# ─── 7. idb_companion 进程 ───
COMPANION_PID=$(pgrep -f "idb_companion" 2>/dev/null | head -1)
if [ -n "$COMPANION_PID" ]; then
  check "idb_companion process" "$PASS" "running (PID: $COMPANION_PID)"
else
  check "idb_companion process" "$WARN" "not running (will auto-start on MCP server launch)"
fi

# ─── 8. iOS Simulator ───
BOOTED_SIM=$(xcrun simctl list devices booted -j 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted':
            print(f\"{d['name']} ({d['udid'][:8]}...)\")
            sys.exit(0)
print('none')
" 2>/dev/null)
if [ "$BOOTED_SIM" != "none" ]; then
  check "iOS Simulator" "$PASS" "$BOOTED_SIM"
else
  check "iOS Simulator" "$WARN" "no booted simulator — run: xcrun simctl boot 'iPhone 16'"
fi

# ─── Summary ───
echo ""
echo "═══════════════════════════════════════"
pass_count=$(printf '%s\n' "${results[@]}" | grep -c "$PASS" || true)
warn_count=$(printf '%s\n' "${results[@]}" | grep -c "$WARN" || true)
fail_count=$(printf '%s\n' "${results[@]}" | grep -c "$FAIL" || true)

if [ "$fail_count" -eq 0 ] && [ "$warn_count" -eq 0 ]; then
  echo "🎉 全部通过 ($pass_count/$pass_count)"
  exit 0
elif [ "$fail_count" -eq 0 ]; then
  echo "⚠️  $warn_count 个警告, $pass_count 个通过"
  exit 0
else
  echo "❌ $fail_count 个失败, $warn_count 个警告, $pass_count 个通过"
  echo "   运行: bash check-ios-simulator-mcp.sh --fix 自动修复"
  exit 1
fi
