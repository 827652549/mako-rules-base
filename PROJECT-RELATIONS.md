# 项目关系

各项目之间的关系说明，自然语言维护，随手更新。

---

## mako-platform
聚合平台，集成博客和个人网站，致力于打造 AI 自动化工作流。
- 生产地址: blog.1heng.top
- Linear Project: mako-platform
- 被 mako-ai-app-rn-for-blog 作为 H5 内嵌页面使用

## mako-ai-app-rn-for-blog
mako-platform 的 React Native 壳，用于打包成原生 App 上架。
- 内嵌 mako-platform 的 H5 页面，壳本身不含业务逻辑
- Linear Project: mako-ai-app-rn-for-blog

## mako-ai-app-job-analyze
宏观市场岗位分析工具，独立应用。
- 生产地址: mako-ai-app-job-analyze.vercel.app
- Linear Project: mako-ai-app-job-analyze

## mako-ai-claude-manager
管理本地 ~/.claude 目录下的配置（skills、agents、MCP、权限、记忆等），可视化操作。
- 管理对象覆盖所有接入 mako-rules-base 的项目
- Linear Project: mako-ai-claude-manager

## mako-rules-base
所有项目的共享规范库，提供 skills、agents、rules、hooks 的统一分发。
- 每个项目通过 `init-project.sh` 接入，建立 symlink
- Linear Project: mako-rules-base
- 被以上所有项目依赖
