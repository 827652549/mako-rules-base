# 代码示例库（Next.js）

> 通用异步/校验示例见 `base/code-examples.md`。

## 表单处理（React Hook Form + Zod）

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email: z.string().email('请输入有效的邮箱地址'),
  password: z.string().min(8, '密码至少8个字符'),
});

type FormValues = z.infer<typeof schema>;

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormValues>({ resolver: zodResolver(schema) });

  const onSubmit = (data: FormValues) => {
    // 处理表单提交
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <p>{errors.email.message}</p>}
      <input type="password" {...register('password')} />
      {errors.password && <p>{errors.password.message}</p>}
      <button type="submit">登录</button>
    </form>
  );
}
```

## Server Action（Next.js App Router）

```typescript
// app/actions/post.ts
'use server';

import { auth } from '@/lib/auth';
import { createPostSchema } from '@/lib/schemas';

export async function createPost(rawInput: unknown) {
  const session = await auth();
  if (!session) throw new Error('Unauthorized');

  const input = createPostSchema.parse(rawInput);
  // 业务逻辑...
}
```

## API Route

```typescript
// app/api/posts/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(req: NextRequest) {
  try {
    const data = await fetchPosts();
    return NextResponse.json({ data });
  } catch (e) {
    console.error('[api/posts GET]', e);
    return NextResponse.json(
      { error: { errorCode: 'error500', errorMsg: '服务器内部错误' } },
      { status: 500 }
    );
  }
}
```
