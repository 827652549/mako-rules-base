# Mako Rules Base — 共享规范入口

所有接入项目在根目录 `CLAUDE.md` 顶部加入以下一行即可引用全部共享规范：

```
@../mako-rules-base/CLAUDE.md
```

## 接入新项目（标准 2 步）

```bash
# 1. 引入共享规范（在新项目根目录执行）
echo '@../mako-rules-base/CLAUDE.md' | cat - CLAUDE.md > tmp && mv tmp CLAUDE.md

# 2. 建 agents symlink
mkdir -p .claude/agents && cd .claude/agents
ln -sf ../../../mako-rules-base/claude/agents/repo-worker.md .
ln -sf ../../../mako-rules-base/claude/agents/web-researcher.md .
```

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
