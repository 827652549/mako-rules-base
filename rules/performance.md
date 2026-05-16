# 性能优化规范

> **适用范围**：仅适用于 Next.js App Router 项目。

## 渲染策略选择

优先使用服务端渲染，按需降级到客户端：

| 场景 | 策略 | 说明 |
|------|------|------|
| 静态内容（博客、文档） | RSC + `generateStaticParams` | 构建时生成，CDN 缓存 |
| 动态数据（用户相关） | RSC + `fetch` with `no-store` | 每次请求重新获取 |
| 交互组件（表单、弹窗） | `'use client'` | 尽量下推到叶子节点 |
| 实时数据（消息、通知） | Client + SWR/React Query | 客户端轮询或 WebSocket |

- **`'use client'` 边界尽量下沉**：包裹最小的交互单元，避免整页客户端渲染
- 禁止对纯展示组件（无事件、无 hooks）加 `'use client'`

## 数据获取

### 服务端
- 并行独立请求，避免串行瀑布：用 `Promise.all` 并行 fetch

```typescript
// 正确：并行获取
const [user, posts] = await Promise.all([
  fetchUser(id),
  fetchPosts(id),
]);

// 错误：串行获取
const user = await fetchUser(id);
const posts = await fetchPosts(id); // 等待 user 完成才开始
```

- RSC 内直接调用数据库（通过 service 层），不经过 HTTP API，减少网络开销

### 客户端
- 使用 SWR 或 React Query 管理服务端状态，禁止在 `useEffect` 中裸 fetch
- 列表数据必须实现分页或无限滚动，禁止一次性加载全量数据

## 图片优化

- 所有 `<img>` 替换为 `next/image` 的 `<Image>`，自动 WebP 转换和懒加载
- 首屏可见图片设置 `priority={true}`
- 外部图片域名需在 `next.config.ts` 的 `images.remotePatterns` 中声明

## 代码分割

- 非首屏组件（弹窗、抽屉、复杂图表）使用 `dynamic` 懒加载

```typescript
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <Skeleton />,
});
```

- 路由级别的代码分割由 App Router 自动处理，无需手动配置

## Bundle 体积

- 引入新依赖前先用 `bundlephobia.com` 评估体积，单包 gzip 超过 50KB 需说明必要性
- 只引入用到的模块，避免全量 import：
  ```typescript
  // 正确
  import { format } from 'date-fns';
  // 错误
  import * as dateFns from 'date-fns';
  ```
- 定期运行 `ANALYZE=true bun run build` 检查 bundle 分析报告

## 缓存策略

- Next.js `fetch` 默认缓存，动态数据显式声明 `cache: 'no-store'`
- 数据库查询结果在单次请求内可用 React `cache()` 去重（同一请求多处调用同一查询）

```typescript
import { cache } from 'react';

export const getUser = cache(async (id: string) => {
  return db.select().from(users).where(eq(users.id, id)).limit(1);
});
```

- Redis 缓存按需引入，用于跨请求共享的高频只读数据（如配置、权限列表）

## 提交前检查清单

提 PR 前验证以下项目：

- [ ] `bun run build` 无 warning（尤其是未使用的 `'use client'`）
- [ ] 新增图片使用了 `next/image`
- [ ] 新增的客户端组件边界是否可以进一步下沉
- [ ] 新增的列表接口有分页参数
