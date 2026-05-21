# Linear API 使用规范

## 速率限制

Linear API 限制为 **2500 次请求 / 小时**（滚动窗口，query 和 mutation 均计入）。

## 核心原则

### 1. 先读后写，批量操作

同一任务内，**先执行所有读操作（query），再执行所有写操作（mutation）**。
不要读写交替，每次切换都消耗额外配额。

```python
# ❌ 错误：读写交替
get_issue()       # 1 次
save_comment()    # 1 次
get_issue()       # 1 次（重复读）
save_issue()      # 1 次

# ✅ 正确：先批量读，再批量写
get_issue()       # 1 次
list_comments()   # 1 次
# ... 处理逻辑 ...
save_comment()    # 1 次
save_issue()      # 1 次
```

### 2. Mutation 之间必须间隔 1 秒

Linear 对 mutation 有更严格的 burst 限制。每次写操作后 sleep 1 秒：

```python
# MCP 工具：settings.json 中的 hook 已自动处理
# "matcher": "mcp__linear__save_*" → sleep 1

# 直接 HTTP API 调用时，必须手动加间隔
save_comment(...)
time.sleep(1)     # 必须
save_issue(...)
time.sleep(1)     # 必须
save_comment(...)
```

### 3. 会话内缓存，禁止重复查询

同一会话中已读取的 issue 数据**直接复用，不重复调用 `get_issue`**。

```python
# ❌ 错误
issue = get_issue("MAK-326")   # 第一次
# ... 一段时间后 ...
issue = get_issue("MAK-326")   # 重复，浪费配额

# ✅ 正确：缓存结果，整个会话复用
issue = get_issue("MAK-326")   # 只调用一次
team_id = issue.team.id        # 后续直接用变量
```

### 4. 禁止 poll Linear API

不要用轮询方式检查状态是否恢复。每次 poll 本身也消耗配额，形成恶性循环。

```bash
# ❌ 错误：poll 检查限流是否恢复（每次都消耗 1 次配额）
until curl linear-api; do sleep 10; done

# ✅ 正确：固定等待足够长的时间后一次性重试
sleep 300  # 等 5 分钟，不 poll
```

### 5. 直接 HTTP 调用时的降级策略

当 MCP 工具不可用而使用直接 HTTP 调用时：
- 每次 mutation 前 `time.sleep(1)`
- 遇到 429 错误时，**停止重试，记录待办，等用户手动触发**
- 不要自动重试 429 — 重试本身也消耗配额

```python
def gql_with_limit(query, variables=None):
    payload = ...
    try:
        return call_api(payload)
    except HTTPError as e:
        if "Rate limit" in e.read().decode():
            raise RateLimitError("配额耗尽，请稍后手动重试")
        raise
```

## 配额估算参考

| 操作场景 | 消耗次数 |
|---------|---------|
| Boot Sequence（读 issue + 读评论） | 2 次 |
| research-phase（写 5 条评论 + 创建 5 个子任务 + 更新状态） | ~11 次 |
| 开发阶段（更新子任务状态 × N + 更新主任务） | N+1 次 |
| 发布收尾（写评论 + 更新状态 + 更新标题） | 3 次 |
| **单项目完整流程合计** | **~20 次** |

正常使用远低于 2500 次/小时限制。触发限流通常是因为**重复查询或高频 poll**。

## Project 寻址规范

### 问题

Linear issue 需要关联 project 时，不能假设 project ID 已知。正确做法是**按名称动态查询**，而不是硬编码 ID。

### 寻址方式：按 GitHub 仓库名匹配 Project 名称

约定：**Linear project 名称 = GitHub 仓库名**（如 `mako-ai-app-job-analyze`）。

**标准查询流程：**

```python
# Step 1：列出所有 projects，按名称匹配
r = gql("query { projects { nodes { id name } } }")
projects = r["data"]["projects"]["nodes"]
project = next((p for p in projects if p["name"] == REPO_NAME), None)
project_id = project["id"] if project else None

# Step 2：创建/更新 issue 时带上 projectId
gql("mutation($t:String!,$teamId:String!,$projectId:String){issueCreate(input:{title:$t,teamId:$teamId,projectId:$projectId}){success issue{identifier}}}",
    {"t": title, "teamId": team_id, "projectId": project_id})
```

**MCP 工具版本：**

```
# 先查询
mcp__linear__list_projects() → 找到与 REPO_NAME 同名的 project → 取 id

# 再创建 issue 时传入
mcp__linear__save_issue(title=..., teamId=..., projectId=project_id)
```

### 在 Boot Sequence 中的位置

`第零步` 解析环境变量时，同步解析 project ID：

```bash
# 已有变量
REPO_NAME=$(basename "$REPO_ROOT")   # = mako-ai-app-job-analyze

# 新增：通过名称匹配获取 Linear project ID
# (在首次 get_issue 时顺带查 project，避免额外请求)
PROJECT_ID=$(issue.project.id)       # 从主任务 issue 中直接读取
```

> **优先从主任务 issue 的 `project.id` 字段读取**（一次 get_issue 即可得到），只有在需要创建新 issue 时才需要单独查询。

### 错误情况处理

| 情况 | 处理 |
|------|------|
| project 不存在 | 跳过 projectId，issue 创建在 team 根目录下，并在评论中说明 |
| project 名称不唯一 | 取第一个匹配项，并在评论中说明 |
| projects 查询失败（限流）| 不阻塞 issue 创建，projectId 留空，后续补挂 |

## 产出输出规范

### Linear 链接格式

**Claude Code 终端 session 中**（用户可 Command+click）：
- 使用 `linear://issue/{ISSUE_IDENTIFIER}` 格式，直接调起 Linear Mac 应用
- 示例：`linear://issue/MAK-366`
- **不要使用** `https://linear.app/...` 格式（会打开浏览器而非 Linear app）

**Linear 评论中**（用户已经在 Linear 里）：
- 不需要输出 Linear 链接，只输出 PR / Preview / Production 等外部链接

### Agent 评论格式（折叠区块）

Agent 写入 Linear 的过程态评论必须使用折叠区块，避免评论过长导致 Human 滚动困难。

**格式模板：**
```markdown
+++ {emoji} {Agent名称} | {内容总结} | 触发：{如何触发的}

[详细内容，包括：
- 执行步骤
- 产出摘要
- 关键决策点
- 需要 Human 关注的事项]

+++
```

**折叠区块语法说明：**
- `+++` 是 Linear 支持的折叠区块标记
- 第一行 `+++` 后面的内容是折叠标题，Human 可以看到
- 两个 `+++` 之间是折叠内容，需要点击展开才能看到
- 标题必须包含：执行者名称 + 内容总结 + 触发方式

**各执行者折叠区块标题示例：**

| 执行者 | 标题格式 | 触发时机 |
|--------|---------|---------|
| PRD Agent | `+++ 📋 PRD Agent | {内容总结} | 触发：{触发方式}` | Human 创建 issue 后自动执行 |
| UX Agent | `+++ 🎨 UX Agent | {内容总结} | 触发：{触发方式}` | PRD 完成后自动执行 |
| UI Agent | `+++ 🖌️ UI Agent | {内容总结} | 触发：{触发方式}` | UX 方案完成后自动执行 |
| TRD Agent | `+++ 📋 TRD Agent | {内容总结} | 触发：{触发方式}` | PRD/UX/UI 完成后自动执行 |
| Task Breakdown | `+++ 📋 Task Breakdown | {内容总结} | 触发：{触发方式}` | TRD 完成后自动执行 |
| repo-worker | `+++ 🔧 repo-worker | {内容总结} | 触发：{触发方式}` | project-lead 派发任务后自动执行 |
| test-phase | `+++ 🧪 test-phase | {内容总结} | 触发：{触发方式}` | 开发完成后自动执行 |
| release-phase | `+++ 🚀 release-phase | {内容总结} | 触发：{触发方式}` | Human 显式授权后自动执行 |
| report-phase | `+++ 📊 report-phase | {内容总结} | 触发：{触发方式}` | 项目完成后自动生成 |

**折叠区块内容要求：**
1. 摘要放在最前面（折叠标题已经包含摘要，但展开后也要有摘要）
2. 详细内容用二级标题分隔
3. 关键决策点用加粗标注
4. 需要 Human 关注的事项用 ⚠️ 标记
5. 代码示例用代码块包裹
