# 项目总览

各项目注册信息与关系说明。`init-project.sh` 自动维护注册部分，关系部分随手手动更新。

---

## mako-platform
- **路径**: /Users/mako/WebstormProjects/mako-cursor-ai-template-for-mako-platform
- **Linear**: mako-platform
- **注册时间**: 2026-05-15
- **说明**: 聚合平台，集成博客和个人网站，致力于打造 AI 自动化工作流
- **生产地址**: blog.1heng.top
- **关系**: 被 mako-ai-app-rn-for-blog 作为 H5 内嵌页面使用

## mako-ai-app-rn-for-blog
- **路径**: /Users/mako/WebstormProjects/mako-ai-app-rn-for-blog
- **Linear**: mako-ai-app-rn-for-blog
- **注册时间**: 2026-05-15
- **说明**: mako-platform 的 React Native 壳，用于打包成原生 App 上架
- **关系**: 内嵌 mako-platform 的 H5 页面，壳本身不含业务逻辑

## mako-ai-app-job-analyze
- **路径**: /Users/mako/WebstormProjects/mako-ai-app-job-analyze
- **Linear**: mako-ai-app-job-analyze
- **注册时间**: 2026-05-15
- **说明**: 宏观市场岗位分析工具，独立应用
- **生产地址**: mako-ai-app-job-analyze.vercel.app

## mako-ai-claude-manager
- **路径**: /Users/mako/WebstormProjects/mako-ai-claude-manager
- **Linear**: mako-ai-claude-manager
- **注册时间**: 2026-05-15
- **说明**: 管理本地 ~/.claude 目录下的配置（skills、agents、MCP、权限、记忆等），可视化操作
- **关系**: 管理对象覆盖所有接入 mako-rules-base 的项目

## mako-rules-base
- **路径**: /Users/mako/WebstormProjects/mako-rules-base
- **Linear**: mako-rules-base
- **注册时间**: 2026-05-15
- **说明**: 所有项目的共享规范库，提供 skills、agents、rules、hooks 的统一分发
- **关系**: 被以上所有项目依赖

