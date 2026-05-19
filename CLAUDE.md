# Mako Rules Base — 共享规范入口

所有接入项目在根目录 `CLAUDE.md` 顶部加入两行：

```
@../mako-rules-base/CLAUDE.md
@../mako-rules-base/rules/{platform}-platform.md
```

其中 `{platform}` 为：`nextjs` / `ios` / `expo` / `python`。

## 接入新项目（一键）

在新项目根目录执行：

```bash
bash ../mako-rules-base/scripts/init-project.sh
```

脚本幂等，重复执行安全，已存在的内容自动跳过。脚本会交互式询问平台类型，并自动写入正确的 `@import` 行。

---

@rules/base/ai-interaction.md
@rules/base/coding-style.md
@rules/base/lint-requirements.md
@rules/base/ui-style-standards.md
@rules/base/api-standards.md
@rules/base/testing-standards.md
@rules/base/code-examples.md
@rules/base/glossary.md
@rules/base/faq.md
@rules/base/linear-api.md
@rules/base/git-conventions.md
@rules/base/security.md
@rules/base/monitoring.md
