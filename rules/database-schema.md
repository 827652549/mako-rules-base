# 数据库 Schema 规范

> **适用范围**：仅适用于使用 Drizzle ORM + PostgreSQL 的 Next.js 项目。

## 文件组织

```
src/db/
├── schema/
│   ├── index.ts        # 统一导出所有表
│   ├── users.ts        # 每张表单独一个文件
│   └── posts.ts
├── index.ts            # drizzle 实例导出
└── migrations/         # drizzle-kit 自动生成，禁止手工修改
```

- 每张表单独一个文件，文件名用复数小写：`users.ts`、`posts.ts`
- `schema/index.ts` 统一 re-export，避免跨文件直接 import 某张表

## 表命名约定

- 表名：`snake_case` 复数，如 `user_profiles`、`post_comments`
- 字段名：`snake_case`，如 `created_at`、`user_id`
- 主键统一命名为 `id`，类型优先使用 `uuid`

```typescript
import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});
```

## 必填字段约定

每张业务表必须包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `uuid` | 主键，`defaultRandom()` |
| `created_at` | `timestamp` | 创建时间，`defaultNow()` |
| `updated_at` | `timestamp` | 更新时间，应用层负责更新 |

软删除场景额外加 `deleted_at timestamp`，查询时加 `IS NULL` 过滤。

## 关联关系

- 外键字段命名：`{被引用表单数}_id`，如 `user_id`、`post_id`
- 必须声明 `references`，使 drizzle-kit 能生成正确迁移
- 级联删除需显式声明 `onDelete: 'cascade'`，默认不级联

```typescript
export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  authorId: uuid('author_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull(),
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
});
```

## 迁移规范

- **只用 drizzle-kit 生成迁移**：`bun run db:generate`，禁止手写 SQL 迁移文件
- **迁移前必须 review** `migrations/` 目录下新生成的 SQL，确认无破坏性变更
- **破坏性变更**（删列、改类型、重命名）需在 PR description 中说明原因和回滚方案
- **生产环境迁移**：通过 `bun run db:migrate` 执行，禁止直接 `db:push`

## 类型导出

schema 定义即类型来源，禁止在 `types/` 中重复定义数据库实体类型：

```typescript
import { users } from '@/db/schema';
import { InferSelectModel, InferInsertModel } from 'drizzle-orm';

export type User = InferSelectModel<typeof users>;
export type NewUser = InferInsertModel<typeof users>;
```

## 查询规范

- 数据访问层只允许在 `src/app/api/` 和 `src/db/` 内直接使用 drizzle 实例
- 组件和 hooks 禁止直接 import drizzle 实例，必须通过 API Routes 访问
- 批量查询必须加 `limit`，防止全表扫描

```typescript
// 正确：在 API Route 中查询
const result = await db.select().from(users).where(eq(users.id, id)).limit(1);

// 错误：在组件内直接查询数据库
```
