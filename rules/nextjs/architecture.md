# Next.js 应用架构约定

## 三层架构

所有业务代码严格按三层拆分，禁止跨层直接调用：

```
表现层（UI）      src/components/,  src/app/**/page.tsx
      ↓
业务逻辑层        src/hooks/,  src/services/
      ↓
数据访问层        src/app/api/,  src/db/
```

跨层直接调用需在 PR description 中说明原因。

## 标准目录约定

```
src/
├── app/            # Next.js App Router（路由即目录结构）
│   └── api/        # API Routes（后端接口）
├── components/
│   └── ui/         # shadcn/ui 原始组件（不直接修改）
├── hooks/          # 自定义 React Hooks，封装复用逻辑
├── services/       # 业务逻辑，包含 API 调用和数据处理
├── utils/          # 纯函数工具，无副作用
├── constants/      # 常量定义
├── types/          # TypeScript 类型定义
├── db/
│   └── schema/     # Drizzle ORM schema 定义
└── lib/            # 第三方库初始化配置
```

## 数据流向

1. 用户交互 → 组件内事件处理函数
2. 事件处理 → 调用 hooks / services
3. Services → API 调用，处理响应
4. 数据 → 通过 hooks / props 回流组件
5. 组件重渲染

## UI 变更约束

在页面上新增 UI 元素前，必须先向用户确认放置位置和视觉设计，禁止自行决定。

## 目录文档约定

每个目录都应有对应的 README.md，简要说明：
- 该目录的职责
- 什么情况下应在此目录新增内容
