# Lint 检查要求（Next.js / JS / TS）

> 通用原则见 `base/lint-requirements.md`。

## 运行 Lint

```bash
bun run lint        # 检查
bun run lint:fix    # 自动修复
```

## 常见问题

### Jest 配置文件（jest.config.js, jest.setup.js）

CommonJS `require()` 导致 ESLint 报错 → 在 `eslint.config.mjs` 的 `globalIgnores` 中忽略：

```javascript
globalIgnores(["jest.config.js", "jest.setup.js"])
```

### React Hooks — setState 在 effect 中

`useEffect` 内直接调用 `setState` 导致 cascading renders：
- 用 `useState` 初始化函数替代
- 在事件回调中调用（允许）
- 用 `useMemo` 计算派生状态

### 未使用的变量 / 导入

- 优先真正使用或删除，不用 `// eslint-disable` 掩盖
- 暂时不用的参数改用下划线前缀 `_param`（最后手段）

### TypeScript 类型

- 用 `unknown` 替代 `any`
- 用 `Record<string, never>` 替代空对象 `{}`

### Next.js 自动生成文件

`types/validator.ts`、`types/routes.d.ts` 等在 `globalIgnores` 中忽略，不手动修改。

## 提交前检查清单

- [ ] `bun run lint` 无 error
- [ ] `--fix` 修复后确认结果正确
