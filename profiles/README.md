# 项目 Profile

Profile 决定加载哪些技术栈规则，不改变安全底线。

| 项目类型 | 推荐规则组合 |
|---|---|
| backend | `stacks/backend-general.md` + 数据、权限、可观测性 |
| frontend | `stacks/frontend-general.md` + API 契约、可访问性、安全 |
| fullstack | backend + frontend + integration |
| mobile | `stacks/mobile-general.md` + API 契约、隐私、安全 |
| ai-llm | `stacks/ai-llm-app.md` + backend/frontend 按实际组成 |
| library-sdk | architecture + testing + delivery + compatibility |
| cli | architecture + testing + delivery + security |
| data-platform | data migration + observability + security |
| generic | 仅加载 `AI-START.md` 路由出的核心规则 |

Profile 是组合，不是复制。具体框架和命令写入项目的 `ai-spec.yaml`，不写进通用模板。

