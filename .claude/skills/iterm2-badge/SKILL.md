---
name: iterm2-badge
description: 设置 iTerm2 标签栏 Badge，用于标注当前 session 的工作内容。支持设置文字和清除。
context: standalone
user-invocable: false
allowed-tools:
  - Bash
---

# iTerm2 Badge — session 标签栏标记

读取传入参数，立即执行 bash 命令写入 iTerm2 badge。

## 前置条件

需要 `$ITERM_TTY` 环境变量已设置（`.zshrc` 中 `export ITERM_TTY=$(tty)`）。

## 执行

根据传入参数判断：

### 非 `--clear` 参数 → 设置 Badge

直接用传入的字符串作为 badge 内容写入：

```bash
printf '\e]1337;SetBadgeFormat=%s\a' "$(echo -n "<传入参数>" | base64)" > "$ITERM_TTY"
```

### `--clear` → 清除 Badge

```bash
printf '\e]1337;SetBadgeFormat=\a' > "$ITERM_TTY"
```

执行完毕即结束，不需要额外输出。
