# UI 样式和组件规范（Next.js / Web）

## 样式规范

- 所有文字内容区必须做溢出打点兼容：`overflow: hidden; text-overflow: ellipsis; white-space: nowrap`（Tailwind：`truncate`）

## 组件规范

- 所有可点击元素（`<button>`、shadcn `Button`、任何触发交互的元素）必须有 `cursor-pointer`
- Tailwind：`className="cursor-pointer"`
- shadcn/ui `Button` 组件默认已含 `cursor-pointer`，无需额外添加
