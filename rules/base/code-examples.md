
# 代码示例库（通用）

> 平台专属示例见对应平台的 `code-examples.md`。

## 异步请求与错误处理

```typescript
// 标准 async/await 请求模式：catch 后返回降级值，不吞掉异常
export async function fetchUser(userId: string): Promise<User | null> {
  try {
    const response = await apiClient.get<User>(`/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error('[fetchUser]', error);
    return null;
  }
}
```

## 输入校验（Zod）

```typescript
import { z } from 'zod';

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
});

// 在边界处解析，内部函数直接使用已校验的类型
const input = createPostSchema.parse(rawInput);
```
