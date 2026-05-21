---
name: research-phase
description: 需求调研阶段。协调 PRD Agent → UX Agent → UI Agent → TRD Agent → Task 拆分，各 Agent 独立写入 Linear。
context: fork
user-invocable: false
allowed-tools:
  - WebSearch
  - mcp__linear__get_issue
  - mcp__linear__save_comment
  - mcp__linear__list_comments
  - mcp__linear__save_issue
  - Agent
---

# Research Phase — 调研阶段

你正在执行需求调研阶段。**你是协调者，不直接写评论，而是调用各个 Agent 执行任务。**

## 核心原则

- **只有 Agent 有评论的能力，Skill 只是协调者**
- 各 Agent 独立执行任务，用自己的名称写评论
- research-phase 负责协调流程，不直接产出内容

## 输入

从父线程传入的上下文：
- Linear issue ID 和标题
- 需求/技改背景描述
- 仓库路径（如适用）

## 流程

### 1. 判定分支

读取 Linear issue 描述，判定是**需求**还是**技改**：

- **分支 A · 需求**：触发器是用户行为/业务指标问题（"用户做不到 X"、"转化率低于 Y"）
  → 走 PRD → UX → UI → TRD → Task 拆分
- **分支 B · 技改**：触发器是工程指标问题（"P95 > 800ms"、"构建时间超过 10 分钟"）
  → 直接走 TRD → Task 拆分

**判定不清** → 在 Linear 写评论说明需要澄清的点，不要硬猜。

### 2a. 分支 A — Step 1：调用 PRD Agent

调用 PRD Agent 执行需求分析：

```
Agent("prd-agent", prompt="你是 PRD Agent，负责分析需求并产出 PRD。

## 任务
分析 Linear issue 的需求背景，产出 PRD

## 输入
- Linear issue ID: {issue_id}
- 需求背景: {description}

## 输出要求
使用折叠区块格式写入 Linear 评论：
+++ 📋 PRD Agent | 需求分析总结 | 触发：Human 创建 issue 后自动执行

[PRD 内容]

+++

## PRD 结构
- 主语：使用'用户'作为主语
- 问题语言：用'用户做不到 X'的句式描述问题
- 非目标价值：显式列出本期不做什么、为什么不做
- 验收标准：用用户行为 / 业务指标描述，必须可观测、可埋点

## 禁止
- 不写技术方案
- 不指定技术栈、库版本、表结构")
```

### 2b. 分支 A — Step 2：调用 UX Agent

PRD 完成后，调用 UX Agent：

```
Agent("ux-agent", prompt="你是 UX Agent，负责产出用户体验方案。

## 任务
基于 PRD，产出用户体验方案

## 输入
- Linear issue ID: {issue_id}
- PRD 内容: {prd_content}

## 输出要求
使用折叠区块格式写入 Linear 评论：
+++ 🎨 UX Agent | 用户体验方案 | 触发：PRD 完成后自动执行

[UX 方案内容]

+++

## UX 方案结构
- 用户流程图：用文字描述核心用户旅程（Happy Path + 异常路径）
- 信息架构：列出页面/视图清单及层级关系
- 交互规格：对关键交互逐一描述
- UX 验收检查点：从 UX 角度列出可测试的验收项

## 禁止
- 不改 PRD 主体目标
- 不指定技术实现
- 不涉及视觉样式")
```

### 2c. 分支 A — Step 3：调用 UI Agent

UX 方案完成后，调用 UI Agent：

```
Agent("ui-agent", prompt="你是 UI Agent，负责产出视觉设计规范。

## 任务
基于 UX 方案，产出视觉设计规范

## 输入
- Linear issue ID: {issue_id}
- UX 方案: {ux_content}

## 输出要求
使用折叠区块格式写入 Linear 评论：
+++ 🖌️ UI Agent | 视觉设计规范 | 触发：UX 方案完成后自动执行

[UI 设计规范内容]

+++

## UI 设计规范结构
1. Figma / Preview URL（如有）
2. 页面布局描述：每个区块的结构、层级、内容说明
3. 设计规范 JSON：colors、spacing、borderRadius、typography token
4. 组件清单：列出使用的 shadcn/ui 组件及其 props 用法
5. 交互行为描述：hover/focus/active 状态、动画、过渡效果

## 设计质量要求
- 遵循 shadcn/ui 美学：极简克制、zinc 灰阶主色、1px 精致边框、4px 网格系统
- 默认带柔和投影营造立体感，hover 时阴影加深上浮
- 使用项目已有的 shadcn/ui 组件
- CSS 变量色值（支持暗色模式），不硬编码 hex
- 响应式布局（sm/md/lg/xl 断点）

## 禁止
- 不写任何代码文件
- 不修改项目代码
- 不执行 git 操作
- 不改 UX 流程结构
- 不改 PRD 目标")
```

### 2d. 分支 A — Step 4：调用 TRD Agent + Task Breakdown Agent

PRD + UX + UI 完成后，调用 TRD Agent 和 Task Breakdown Agent：

```
Agent("trd-agent", prompt="你是 TRD Agent，负责产出技术方案。

## 任务
基于 PRD + UX + UI 三份产物，产出 TRD

## 输入
- Linear issue ID: {issue_id}
- PRD: {prd_content}
- UX 方案: {ux_content}
- UI 设计规范: {ui_content}

## 输出要求
使用折叠区块格式写入 Linear 评论：
+++ 📋 TRD Agent | 技术方案 | 触发：PRD/UX/UI 完成后自动执行

[TRD 内容]

+++

## TRD 结构
- 主语：系统 / 工程
- 问题语言：'系统不满足约束 Z'
- 非目标价值：显式列出不优化哪些模块
- 验收标准：工程指标 / 兼容性测试用例（可跑、可量化）
- 技术方案：架构概览、组件设计、安全设计、现有系统兼容")
```

```
Agent("task-breakdown-agent", prompt="你是 Task Breakdown Agent，负责产出任务拆分。

## 任务
基于 PRD + UX + UI + TRD，产出任务拆分

## 输入
- Linear issue ID: {issue_id}
- PRD: {prd_content}
- UX 方案: {ux_content}
- UI 设计规范: {ui_content}
- TRD: {trd_content}

## 输出要求
使用折叠区块格式写入 Linear 评论：
+++ 📋 Task Breakdown | 任务拆分 | 触发：TRD 完成后自动执行

[Task 拆分内容]

+++

## Task 拆分 JSON 格式
```json
{
  \"tasks\": [
    {
      \"title\": \"Task 标题\",
      \"description\": \"Task 描述（需引用 UX 流程和 UI 规范中的具体内容）\",
      \"step\": 1,
      \"blockedBy\": [],
      \"acceptance\": \"验收标准\"
    }
  ]
}
```

## 拆分原则
- 依据是文件影响域 / 依赖关系，不是工作量
- 同 step 内可并发，跨 step 需串行
- 每个 Task 必须有可机器校验的验收标准
- Task 描述中应引用 UX 交互规格和 UI 组件清单中的具体条目

## 创建 Linear 子任务（必须执行）
Task 拆分 JSON 写入评论后，**必须为每个 Task 创建 Linear 子任务**：
```python
for each task in tasks:
    mcp__linear__save_issue(
        title=task.title,
        description=f\"{task.description}\\n\\n**验收标准**: {task.acceptance}\",
        parentId=\"{主任务 issue ID}\",
        team=\"{主任务 team}\",
        project=\"{主任务 project}\",
        state=\"Todo\"  # 子任务默认 Todo 状态
    )
```

创建后在 Task Breakdown 评论末尾追加子任务 ID 映射，方便 project-lead 后续追踪：
```
子任务 ID 映射：
- {task1.title}: MAK-{子任务编号}
- {task2.title}: MAK-{子任务编号}
```")
```

### 3. 分支 B：调用 TRD Agent + Task Breakdown Agent

直接调用 TRD Agent（同 2d 格式），然后调用 Task Breakdown Agent。

### 4. 用 WebSearch 做必要调研

如有需要竞品分析、技术方案调研的环节，用 WebSearch 搜索后将结果传递给各个 Agent。

## 产物

各 Agent 独立写入 Linear 评论（均使用折叠区块格式）：

**分支 A（需求）**：
1. PRD Agent 写入 PRD（`+++ 📋 PRD Agent | 需求分析总结 | 触发：Human 创建 issue 后自动执行`）
2. UX Agent 写入 UX 方案（`+++ 🎨 UX Agent | 用户体验方案 | 触发：PRD 完成后自动执行`）
3. UI Agent 写入 UI 设计规范（`+++ 🖌️ UI Agent | 视觉设计规范 | 触发：UX 方案完成后自动执行`）
4. TRD Agent 写入 TRD（`+++ 📋 TRD Agent | 技术方案 | 触发：PRD/UX/UI 完成后自动执行`）
5. Task Breakdown Agent 写入任务拆分（`+++ 📋 Task Breakdown | 任务拆分 | 触发：TRD 完成后自动执行`）+ 对应的 Linear 子任务

**分支 B（技改）**：
1. TRD Agent 写入 TRD（`+++ 📋 TRD Agent | 技术方案 | 触发：Human 创建 issue 后自动执行`）
2. Task Breakdown Agent 写入任务拆分（`+++ 📋 Task Breakdown | 任务拆分 | 触发：TRD 完成后自动执行`）+ 对应的 Linear 子任务

## 约束

- **research-phase 是协调者，不直接写评论**
- 各 Agent 独立执行任务，用自己的名称写评论
- PRD 不指定技术栈、库版本、表结构
- UX 不改 PRD 主体目标、不指定技术实现、不涉及视觉样式
- UI 不写任何代码、不改 UX 流程结构、不改 PRD 目标
- TRD 不修改 PRD 主体目标
- 非目标段是架构的笼头 — 顺手优化 = 越权
- 验收标准必须可机器校验
- 所有产物必须写入 Linear 评论，不输出到其他地方
