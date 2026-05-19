# 安全规范（Next.js 特有）

> **适用范围**：仅适用于 Next.js App Router 项目。通用安全规范见 `base/security.md`。

## 认证（Better Auth）
- 所有需要登录的 API Route 必须在处理业务前验证 session
- 使用 Better Auth 提供的 `auth.api.getSession` 获取当前用户，禁止自行解析 cookie 或 JWT

```typescript
// src/app/api/posts/route.ts
import { auth } from '@/lib/auth';

export async function POST(req: Request) {
  const session = await auth.api.getSession({ headers: req.headers });
  if (!session) {
    return Response.json({ error: { errorCode: 'error401', errorMsg: '未认证' } }, { status: 401 });
  }
  // 继续业务逻辑...
}
```

## 权限控制
- 资源操作前必须验证「当前用户是否有权操作该资源」，不能只验证是否登录
- 权限校验在 API Route 层完成，不下沉到 service 层

```typescript
// 查询资源后验证归属，而非依赖查询条件过滤
const post = await db.select().from(posts).where(eq(posts.id, postId)).limit(1);
if (!post[0] || post[0].authorId !== session.user.id) {
  return Response.json({ error: { errorCode: 'error403', errorMsg: '无权限' } }, { status: 403 });
}
```

## Server Actions 安全
- Server Actions 不是"内部函数"，必须同样做认证和权限校验
- 禁止在 Server Actions 中直接信任客户端传入的 userId

## 客户端安全变量
- 只有 `NEXT_PUBLIC_` 前缀的变量会暴露给浏览器，敏感信息禁止使用此前缀
- 客户端代码中禁止出现数据库连接信息、第三方密钥

## XSS 防护
- 禁止使用 `dangerouslySetInnerHTML`，如必须使用需在 PR 中说明原因并使用 DOMPurify 净化
- 用户输入内容渲染时通过 React 的 JSX 插值，不拼接 HTML 字符串

## CORS
- API Routes 默认由 Next.js 限制同源访问，不需要额外配置
- 如需对外开放（第三方调用），在对应 Route 中通过 `headers()` 显式设置 `Access-Control-Allow-Origin`，禁止全局通配符 `*`
