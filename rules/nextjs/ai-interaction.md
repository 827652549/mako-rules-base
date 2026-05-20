# AI 交互指南（Next.js / TypeScript）

> 通用交互约定见 `base/ai-interaction.md`。

## 代码生成偏好

- 优先生成 TypeScript 代码，严格类型检查
- 优先使用 `async/await` 而非 Promise 链
- 优先使用函数组件而非类组件
- 优先使用命名导出而非默认导出（Expo Router 页面除外）
- 优先使用解构赋值提取属性和参数
- 避免使用 `any` 类型，优先使用 `unknown` 或具体类型
- 避免在 `useEffect` 中直接调用 `setState`，使用初始化函数或事件回调
- 生成代码后必须确认可通过 `bun run lint`
