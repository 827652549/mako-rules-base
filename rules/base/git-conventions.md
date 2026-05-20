# Git 分支规范

## 主分支命名

**所有仓库的主分支必须使用 `release`，禁止使用 `main` 或 `master`。**

- 新仓库初始化后，立即将 `main` 重命名为 `release`
- GitHub 上设置 `release` 为默认分支，删除 `main`
- feature 分支从 `release` 创建，合并回 `release`

```bash
# 新仓库初始化
git branch -m main release
git push -u origin release
gh repo edit <owner>/<repo> --default-branch release
git push origin --delete main
```

## 分支命名约定

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `release` | `release` |
| 功能分支 | `feature/{ISSUE_ID}-{描述}` | `feature/MAK-301-pet-photo-upload` |
| 修复分支 | `hotfix/{ISSUE_ID}-{描述}` | `hotfix/MAK-302-login-crash` |

## Worktree 约定

开发任务必须在独立的 git worktree 中进行，feature 分支从 `release` 创建：

```bash
git worktree add "$WORKTREE_PATH" -b "feature/${ISSUE_ID}-${DESCRIPTION}" release
```
