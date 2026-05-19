# 监控与可观测性（Next.js 特有）

> **适用范围**：仅适用于 Next.js App Router 项目。通用错误处理见 `base/monitoring.md`。

## API Route 错误处理
- 所有 API Route 用 try/catch 包裹，未捕获的异常统一返回 `error500`
- 响应格式遵循 `base/api-standards.md` 中的统一结构

```typescript
export async function POST(req: Request) {
  try {
    // 业务逻辑
  } catch (e) {
    console.error('[api/posts POST]', e);
    return Response.json(
      { error: { errorCode: 'error500', errorMsg: '服务器内部错误' } },
      { status: 500 }
    );
  }
}
```

## 客户端错误边界
- 每个独立功能模块（页面级）必须包裹 React `error.tsx`（App Router 约定）
- `error.tsx` 必须展示对用户友好的提示，不暴露原始错误堆栈

```
src/app/
├── dashboard/
│   ├── page.tsx
│   └── error.tsx    # 捕获该路由段内的运行时错误
```

## 性能监控（核心 Web Vitals）
- 使用 Next.js 内置的 `useReportWebVitals` 在 `layout.tsx` 中采集 LCP、FID、CLS
- 本地开发通过 Chrome DevTools Performance 面板验证，不需要集成第三方服务
- 目标阈值：LCP < 2.5s，CLS < 0.1，FID < 100ms

```typescript
// src/app/layout.tsx
'use client';
import { useReportWebVitals } from 'next/web-vitals';

export function WebVitals() {
  useReportWebVitals((metric) => {
    console.log(metric); // 开发阶段打印，生产按需上报
  });
  return null;
}
```

## 日志规范
- **服务端日志**：`console.error` 用于异常，`console.log` 用于关键业务节点，不打印高频循环日志
- **客户端日志**：生产环境禁止 `console.log` 残留，提交前通过 lint 规则清除
- 日志前缀格式：`[模块/操作]`，如 `[api/users POST]`、`[auth/login]`，便于过滤
