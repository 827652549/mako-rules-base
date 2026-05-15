---
name: 提交和审查
version: 1.0.0
description: "代码提交、部署验证、报告生成的标准化审查流程。运行 lint/build → 提交推送 → 等待 Vercel 部署 → 验证页面 → 输出报告 → 更新 changelog。"
---

# 提交和审查

## 用途

将当前变更提交、推送、部署验证，并生成执行报告和更新 changelog。可被 `/linear-to-production` 调用，也可独立使用。

## 触发方式

- 独立使用：用户输入 `/提交和审查`
- 被调用：由 `linear-to-production` skill 在实施完成后自动调用

## 前置条件

- 当前分支上有已完成的代码变更
- 关联的 Linear 任务编号可从 git 分支名或上下文推断

## 执行流程

### 步骤 1：Lint & Build 检查

1. 运行 `bun run lint` 检查 ESLint 报错
   - 如有报错，先尝试 `bun run lint:fix` 自动修复
   - 无法自动修复的，手动修复后再继续
2. 运行 `bun run build` 检查构建是否成功
   - 构建失败则根据错误信息修复代码，直到构建成功
3. lint 和 build 均通过后进入下一步

### 步骤 2：提交 & 推送

1. 确认当前 Linear 任务编号（从分支名、上下文或用户输入获取，格式 `MAK-XXX`）
2. 运行 `git status` 确认待提交文件
3. 运行 `git diff` 查看变更内容
4. 运行 `git log` 查看最近提交记录风格
5. 将变更文件添加到暂存区
6. 创建提交，message 格式：`<类型>: <简要描述> (ref: MAK-XXX)`

   示例：
   ```
   feat: 新增昵称+密码登录功能 (ref: MAK-155)
   fix: 修复生产环境评论删除的缓存问题 (ref: MAK-176)
   ```

7. 推送到远程：`git push origin <当前分支>`
   - 推送完成后向用户输出：`📤 已推送到 {当前分支} 分支`
   - 如为 feature 分支：提示"PR 合并到 release 后将自动部署生产环境"
   - 如为 release 分支：提示"已推送到 release，将自动触发生产环境部署"

### 步骤 3：Vercel 部署验证

1. 推送完成后，使用 `run_in_background` 启动**后台部署检查**（非阻塞）：
   ```bash
   # 后台脚本：每 15 秒检查一次，最多 5 分钟（20 次）
   for i in $(seq 1 20); do
     DEPLOY_STATUS=$(gh api "repos/$GITHUB_REPO/deployments?per_page=1" --jq '.[0].state' 2>/dev/null)
     if [ "$DEPLOY_STATUS" = "success" ]; then
       DEPLOY_URL=$(gh api "repos/$GITHUB_REPO/deployments?per_page=1/statuses" --jq '.[0].target_url' 2>/dev/null)
       echo "DEPLOY_READY:$DEPLOY_URL"
       exit 0
     fi
     sleep 15
   done
   echo "DEPLOY_TIMEOUT"
   ```
   后台任务启动后，**立即继续后续步骤**（更新 changelog 等），不阻塞等待。
2. 后台任务完成时收到通知后，使用 `mcp__chrome-devtools__navigate_page` 导航到 Vercel 页面验证：
   - 首页是否正常加载
   - 本次变更相关页面是否正常
3. 如果页面访问异常：
   - 排查问题（查看 Vercel 日志、浏览器控制台错误）
   - 修复代码
   - 重新提交、推送，回到步骤 3
   - 直到页面正常为止
4. 超时处理：如果返回 `DEPLOY_TIMEOUT`，向用户输出"⏳ 部署超时，请手动检查 Vercel 部署状态"

### 步骤 4：更新 Changelog（仅 changelog.md）

1. 读取项目根目录的 `changelog.md`
2. 根据本次变更性质判断版本号递增规则：
   - **MAJOR**（X.0.0）：重大架构变更、破坏性 API 改动
   - **MINOR**（0.X.0）：新功能、新模块
   - **PATCH**（0.0.X）：bug 修复、小优化、文案调整
3. 在 changelog 顶部新增版本条目，包含：
   - 版本号和日期
   - 变更条目（关联 `ref: MAK-XXX`）
4. 提交 changelog 变更并推送到当前分支：`git push origin <当前分支>`

### 步骤 5：最终确认

1. 运行 `git status` 确认暂存区和工作区均为干净状态
2. 如有未提交内容，重复步骤 2

## 注意事项

- 每个步骤遇到网络错误时自动重试（等待 10 秒后重试，最多 3 次），不要求用户手动介入
- 如果无法从上下文推断 Linear 任务编号，询问用户
- 部署等待使用轮询而非长连接，避免超时
- 报告文件使用 UTF-8 编码
- 全程使用中文与用户交互
