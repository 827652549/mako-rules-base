# 错误处理与监控（通用）

## 错误边界原则
- 错误只在边界处（API 入口、顶层组件）捕获和上报，内部函数抛出，不吞掉异常
- `catch` 块必须做两件事之一：向上 rethrow，或上报后返回降级结果
- 禁止空 catch：`catch (e) {}` 是严格禁止的

```typescript
// 错误：吞掉异常
try {
  await doSomething();
} catch (e) {}

// 正确：上报后降级
try {
  await doSomething();
} catch (e) {
  reportError(e);
  return fallbackValue;
}
```

## 错误日志格式
- 上报错误时必须附带上下文：`{ userId, action, input }`
- 不打印用户密码、token 等敏感字段
