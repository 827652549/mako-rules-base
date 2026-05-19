# Expo / React Native 技术栈规范

> **适用范围**：仅适用于 Expo Managed Workflow 项目。
> Next.js / Web 专属规范（shadcn/ui、Tailwind、Drizzle ORM、App Router）**不适用**。

## 技术栈

| 类别 | 选型 |
|------|------|
| 框架 | Expo (Managed Workflow) |
| 路由 | expo-router（文件路由） |
| UI 框架 | React Native |
| 语言 | TypeScript（strict，禁止 `any`） |
| 包管理器 | Bun（首选） |
| 样式 | `StyleSheet.create()`（RN 标准） |

## 目录结构

```
app/                        # Expo Router 文件路由（根目录，不套 src/）
├── _layout.tsx             # Root layout
├── index.tsx               # 首页
├── +not-found.tsx          # 404
└── +html.tsx               # Web 平台 HTML 模板
components/                 # 可复用组件
constants/                  # 常量定义（配置、颜色等）
hooks/                      # 自定义 Hooks
assets/                     # 静态资源（图标、字体、splash）
```

> `app/` 在根目录，遵循 Expo 生态默认约定。

## 命名约定

| 类别 | 规则 | 示例 |
|------|------|------|
| 文件名 | kebab-case | `web-view-container.tsx` |
| 组件 | PascalCase | `WebViewContainer` |
| 变量 / 函数 | camelCase | `canGoBack`, `handleMessage` |
| 常量 | UPPER_SNAKE_CASE | `BLOG_URL` |
| 路由页面 | 必须 default export | Expo Router 约定 |
| 其他模块 | 优先命名导出 | — |

## TypeScript 约束

- `strict: true`（tsconfig 已配置）
- 禁止 `any`，用 `unknown` 替代
- 路径别名：`@/*` → `./*`（根目录级别）

## 样式约定

- 使用 `StyleSheet.create()`，样式定义在组件文件底部
- 颜色从 `constants/colors.ts` 引用，禁止硬编码色值
- 安全区域必须用 `SafeAreaView` 适配

## 状态处理三要素

所有异步数据获取必须处理三种状态：

| 状态 | 展示 |
|------|------|
| loading | `ActivityIndicator` |
| error | 错误页面 + 重试按钮 |
| offline | 网络断开提示 |

## WebView 项目额外约束（如适用）

- WebView URL 统一在 `constants/` 中定义，禁止硬编码
- JS Bridge 消息格式统一：`{ type: string, payload: unknown }`
- 导航控制通过自定义 Hook 封装，支持 `goBack()` / `reload()` / `canGoBack`
- 必须处理 `onError` 和 `onHttpError`

## 代码质量

- ESLint 必须通过才能提交（`bun run lint`）
- 提交前确认 `bun run build` 成功（如适用）

## 验收规范

- Expo 项目无法通过 Vercel Preview 验证 UI，**必须真机验收**
- 构建成功部署到真机后，请 Human 在设备上确认验收
- 不标记 Done 直到 Human 在真机验收通过后显式确认

## macOS 注意事项

- macOS 大小写不敏感文件系统，文件重命名需两步操作（先改临时名再改目标名）
- `ios/*.xcworkspace` 中引用的路径必须与实际一致（prebuild 后可能变化）
