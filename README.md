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
    ├── agents/            # 共享 agent（物理位置在此，各项目 symlink 指向这里）
    │   ├── project-lead.md
    │   ├── repo-worker.md
    │   ├── ui-agent.md
    │   ├── ux-agent.md
    │   └── web-researcher.md
    └── skills/            # 共享编排 skill（所有启用自动化研发流程的项目 symlink 指向这里）
        ├── dev-dispatch
        ├── linear-triage
        ├── release-phase
        ├── report-phase
        ├── research-phase
        ├── review
        └── test-phase
```

## 接入新项目（一键）

在新项目根目录执行：

```bash
bash ../mako-rules-base/scripts/init-project.sh
```

脚本幂等，重复执行安全，已存在的内容自动跳过。

## 维护原则

- 改规则：直接编辑 `rules/*.md`，所有接入项目通过 `@import` 实时生效
- 改 agent：直接编辑 `claude/agents/*.md`，所有 symlink 实时生效
- 改 skill：直接编辑 `claude/skills/<name>/SKILL.md`，所有 symlink 实时生效
- 加新规则：新建 `rules/xxx.md` 并在 `CLAUDE.md` 末尾加一行 `@rules/xxx.md`
- 不在这里放：项目特有的 architecture/glossary

## 升级信号（出现以下情况再建 stacks/ 分层）

1. 出现非 Next.js 项目（Node CLI、Python、Go）
2. 某条规则需要「只对部分项目生效」
