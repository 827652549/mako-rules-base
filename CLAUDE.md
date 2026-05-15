# Mako Rules Base — 共享规范入口

所有接入项目在根目录 `CLAUDE.md` 顶部加入以下一行即可引用全部共享规范：

```
@../mako-rules-base/CLAUDE.md
```

## 接入新项目（一键）

在新项目根目录执行：

```bash
bash ../mako-rules-base/scripts/init-project.sh
```

脚本幂等，重复执行安全，已存在的内容自动跳过。

---

@rules/ai-interaction.md
@rules/coding-style.md
@rules/lint-requirements.md
@rules/react-guidelines.md
@rules/ui-style-standards.md
@rules/api-standards.md
@rules/testing-standards.md
@rules/code-examples.md
@rules/nextjs-stack.md
@rules/nextjs-architecture.md
@rules/glossary.md
@rules/faq.md
@rules/linear-api.md
@rules/git-conventions.md
