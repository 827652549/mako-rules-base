---
name: create-worktree
description: 创建 git worktree，强制约束路径在仓库父目录并列创建。所有 worktree 创建必须通过此 skill。
context: fork
user-invocable: false
allowed-tools:
  - Bash
  - Read
---

# Create Worktree — 统一 worktree 创建

所有 git worktree 创建操作**必须通过此 skill**，禁止直接执行 `git worktree add`。

## 输入

通过 `args` 传入，格式：`ISSUE_ID [REPO_ROOT]`

- `ISSUE_ID`（必须）：issue 标识符，如 `MAK-301`
- `REPO_ROOT`（可选）：仓库根目录，默认从当前目录自动检测

## 执行

### Step 1：解析路径（不可跳过）

```bash
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel)}"
REPO_NAME=$(basename "$REPO_ROOT")
PARENT_DIR=$(dirname "$REPO_ROOT")
WORKTREE_PATH="${PARENT_DIR}/${REPO_NAME}-${ISSUE_ID}"
BRANCH_NAME="feature/${ISSUE_ID}"
```

### Step 2：路径安全校验（强制）

```bash
# 校验 1：worktree 路径不得在 REPO_ROOT 内部
if [[ "$WORKTREE_PATH" == "$REPO_ROOT"* ]]; then
  echo "❌ 错误：worktree 路径 ($WORKTREE_PATH) 在仓库目录内部"
  echo "   正确位置应为父目录并列：$PARENT_DIR/$REPO_NAME-$ISSUE_ID"
  exit 1
fi

# 校验 2：worktree 路径不得与 REPO_ROOT 相同
if [ "$WORKTREE_PATH" = "$REPO_ROOT" ]; then
  echo "❌ 错误：worktree 路径与仓库根目录相同"
  exit 1
fi

# 校验 3：PARENT_DIR 必须存在
if [ ! -d "$PARENT_DIR" ]; then
  echo "❌ 错误：父目录不存在：$PARENT_DIR"
  exit 1
fi
```

### Step 3：检查是否已存在

```bash
if [ -d "$WORKTREE_PATH" ]; then
  echo "⚠️ worktree 已存在：$WORKTREE_PATH"
  echo "   检查分支状态..."
  cd "$WORKTREE_PATH" && git status --short
  # 已存在则跳过创建，直接输出变量
  echo "WORKTREE_PATH=$WORKTREE_PATH"
  echo "BRANCH_NAME=$BRANCH_NAME"
  exit 0
fi
```

### Step 4：创建 worktree

```bash
cd "$PARENT_DIR"
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" release
```

### Step 5：输出结果变量

创建成功后，**必须输出以下变量供调用方使用**：

```
✅ Worktree 创建成功

WORKTREE_PATH=$WORKTREE_PATH
REPO_ROOT=$REPO_ROOT
BRANCH_NAME=$BRANCH_NAME
```

## 约束

- **禁止跳过路径校验**：Step 2 的三项校验缺一不可
- **禁止在 REPO_ROOT 内部创建 worktree**：这是本 skill 存在的核心目的
- **分支从 `release` 创建**：始终基于 release 分支
- **branch 命名格式**：`feature/{ISSUE_ID}`

## 错误处理

| 错误场景 | 处理 |
|---------|------|
| worktree 路径在 REPO_ROOT 内部 | ❌ 中止，输出正确路径提示 |
| worktree 已存在 | ⚠️ 跳过创建，输出已有路径信息 |
| git 命令失败 | ❌ 中止，输出错误信息 |
| 父目录不存在 | ❌ 中止 |
