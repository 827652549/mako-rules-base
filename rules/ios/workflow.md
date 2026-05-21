# iOS 项目工作流规范

> **适用范围**：仅适用于 iOS 原生项目（Swift / SwiftUI）。

## 分支与 PR 约定

iOS 项目沿用 feature 分支 + PR 的可追溯开发模式，但 **PR 无需等待人工 review 即可合并**。

### 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 主分支 | `release` | `release` |
| 功能分支 | `feature/{ISSUE_ID}` | `feature/MAK-301` |
| 修复分支 | `hotfix/{描述}` | `hotfix/crash-on-launch` |

```bash
# 从 release 创建 feature 分支（worktree 模式）
git worktree add "$WORKTREE_PATH" -b "feature/$ISSUE_ID" release
```

## 合并策略

- project-lead agent **无需人工 review 即可自动合并 PR**
- 合并方式：Squash merge（保持 release 分支历史整洁）
- 合并后删除 feature 分支

```bash
gh pr merge <PR_NUMBER> --squash --delete-branch
```

## Semver Tag 发布

合并到 `release` 后，project-lead agent 必须自动打 semver tag。

### Tag 格式

```
v{MAJOR}.{MINOR}.{PATCH}
```

- **不带 issue ID**：纯版本号（`v1.2.0`，而非 `v1.2.0-MAK-301`）
- 对应 Xcode 的 `CFBundleShortVersionString`

### 版本递增规则

| 变更类型 | 递增位 | 示例（当前 v1.2.3） |
|---------|--------|-------------------|
| 新功能（feature 分支） | MINOR，PATCH 归零 | → v1.3.0 |
| Bug 修复（hotfix 分支） | PATCH | → v1.2.4 |
| 破坏性变更（重构/架构调整） | MAJOR，MINOR/PATCH 归零 | → v2.0.0 |

### 版本号确定流程

```bash
# 1. 读取当前最新 tag
LATEST=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# 2. 解析版本号
IFS='.' read -r MAJOR MINOR PATCH <<< "${LATEST#v}"

# 3. 根据合并的分支前缀自动递增
#    feature/* → MINOR++, PATCH=0
#    hotfix/*  → PATCH++
#    breaking  → MAJOR++, MINOR=0, PATCH=0

# 4. 打 tag 并推送
git tag -a "v${MAJOR}.${MINOR}.${PATCH}" -m "Release v${MAJOR}.${MINOR}.${PATCH}"
git push origin "v${MAJOR}.${MINOR}.${PATCH}"
```

### Tag 消息格式

```
Release v1.3.0

Changes:
- MAK-301: 添加宠物照片上传功能
- MAK-302: 修复首页加载闪烁问题
```

## 不触发自动提交

- ❌ 不触发 XcodeCloud 自动构建
- ❌ 不触发 App Store Connect 自动提交
- ✅ Tag 仅用于版本追踪，TestFlight/App Store 发布由人工决策

## Xcode 版本同步

打 tag 后，建议同步更新 Xcode 项目的版本号（可选，作为提醒）：

| Tag | `CFBundleShortVersionString` | `CFBundleVersion` |
|-----|------------------------------|-------------------|
| v1.3.0 | 1.3.0 | 递增整数（如 Build 47） |

> `CFBundleVersion`（Build Number）在提交 App Store 时手动递增，不由 agent 管理。

## 验收规范

> 适用于所有 iOS 相关项目（纯 Swift / Expo / React Native）。

### 第一步：模拟器验收（Agent 自主完成）

构建 Release 版本到 iOS 模拟器，确认 UI 和基本功能正常：

1. **构建 Release 版本**：
   ```bash
   # 纯 iOS/Swift 项目
   xcodebuild -workspace <ProjectName>.xcworkspace \
     -scheme <ProjectName> -configuration Release \
     -destination "platform=iOS Simulator,name=iPhone 16" build
   ```
2. **安装并启动**：
   ```bash
   xcrun simctl install booted <app路径>
   xcrun simctl launch booted <bundle_id>
   ```
3. **截图验证**：使用 `mcp__ios-simulator__screenshot` 确认页面正常显示
4. **最小验收标准**：构建成功 + app 成功打开 + 截图可见正常 UI

### 真机验收（可选，按需）

模拟器验收通过即可标记 Done。仅在以下场景建议 Human 进行真机验收：

- 涉及摄像头、GPS、推送通知等模拟器无法覆盖的硬件能力
- 涉及真机性能敏感场景（大量列表渲染、动画流畅度等）
- Human 主动要求真机确认时

## 完整发布检查清单

- [ ] feature 分支从 `release` 创建
- [ ] PR 已创建并标题含 issue ID（如 `[MAK-301] 添加照片上传`）
- [ ] `git tag` 已打并推送到 remote
- [ ] **Human 确认后**将 Linear issue 状态更新为 Done，写入发布评论（含 tag 版本号）
