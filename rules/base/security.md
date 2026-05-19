# 安全规范（通用）

## 密钥与环境变量
- 所有密钥、token、数据库连接串只允许存放在 `.env.local`，禁止硬编码在源码中
- `.env.local` 必须在 `.gitignore` 中，禁止提交到版本库
- 新增环境变量必须同步更新 `.env.example`（仅保留 key，value 留空或填示例值）

## 输入校验
- 所有来自用户或外部系统的输入，必须在边界处（API 入口）校验，内部函数不重复校验
- 使用 Zod 进行结构校验，禁止手写正则替代

```typescript
import { z } from 'zod';

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
});

// 在 API Route 入口处校验
const body = createPostSchema.parse(await req.json());
```

## 依赖安全
- 定期运行 `bun audit`，修复高危漏洞
- 不引入无维护者或下载量极低的包
