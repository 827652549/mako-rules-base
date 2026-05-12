# Next.js 应用标准技术栈

Mako 所有 Next.js 项目共用的技术选型约定。

## 前端
- **框架**: Next.js App Router（不使用 Pages Router）
- **UI 库**: React 19
- **样式**: Tailwind CSS v4
- **组件**: shadcn/ui（完整组件集，优先复用现有组件，不直接修改 `components/ui/` 内的文件）
- **主题**: 支持深色/浅色模式切换
- **语言**: TypeScript（strict 模式，禁止 `any`）

## 后端
- **API**: Next.js API Routes（`src/app/api/`）
- **认证**: Better Auth（支持登录/注册/会话管理）

## 数据库
- **主库**: PostgreSQL（通过 Drizzle ORM）
- **ORM**: Drizzle ORM + drizzle-kit 迁移
- **缓存**: Redis（按需接入，未默认集成）

## 测试
- Jest + React Testing Library

## 部署
- **主部署**: Vercel（Push 自动触发 CI/CD）
- **本地开发**: Docker Compose（Next.js + PostgreSQL 一键启动）

## 工具链
- **包管理器**: Bun（首选，也兼容 npm/yarn）
- **代码检查**: ESLint，提交前必须通过 `bun run lint`
- **构建验证**: `bun run build` 必须无错误后才能提 PR
