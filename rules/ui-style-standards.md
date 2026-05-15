

# UI样式和组件规范


## 通用样式规范
- 凡是文字的内容区, 都要做好溢出打点兼容的样式。

## UI组件规范
- 凡是Button组件（包括 `<button>`、shadcn `Button`、以及任何可点击元素），必须添加 `cursor-pointer` 样式。
- Tailwind 中使用 `className="cursor-pointer"`，或在 shadcn Button variant 中已内置。
- 如果是 shadcn/ui 的 Button 组件，默认已含 `cursor-pointer`，无需额外添加。
