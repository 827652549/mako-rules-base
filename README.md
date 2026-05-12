# mako-rules-base

Mako 个人项目的 Claude Code 共享规范层。

## 结构

```
mako-rules-base/
├── CLAUDE.md              # 入口，@import 所有 rules
├── rules/                 # 共享编码规范（通用于所有 Next.js 项目）
│   ├── ai-interaction.md
│   ├── coding-style.md
│   ├── lint-requirements.md
│   ├── react-guidelines.md
│   ├── ui-style-standards.md
│   ├── api-standards.md
│   ├── testing-standards.md
│   └── code-examples.md
└── claude/
    └── agents/            # 共享 agent（物理位置在此，各项目 symlink 指向这里）
        ├── repo-worker.md
        └── web-researcher.md
```

## 维护原则

- 改规则：直接编辑 `rules/*.md`，所有接入项目通过 `@import` 实时生效
- 改 agent：直接编辑 `claude/agents/*.md`，所有 symlink 实时生效
- 加新规则：新建 `rules/xxx.md` 并在 `CLAUDE.md` 末尾加一行 `@rules/xxx.md`
- 不在这里放：`project-lead.md`（orchestrator 独有）、`skills/`（orchestrator 独有）、项目特有的 architecture/glossary

## 升级信号（出现以下情况再建 stacks/ 分层）

1. 出现非 Next.js 项目（Node CLI、Python、Go）
2. 某条规则需要「只对部分项目生效」
