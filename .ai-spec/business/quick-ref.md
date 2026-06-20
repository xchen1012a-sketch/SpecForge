# 业务快速参考（AI 实时维护）

> 日常启动唯一入口：普通会话只读本文件；`maintenanceDue` 到期才读 `.ai-spec/workflows/context-maintenance.md`；大文件先搜索并按不超过 250 行分段读取。
> status: TEMPLATE_PLACEHOLDER
> dailyEntry: true
> dynamicContextGate: true
> outputLanguage: zh-CN
> maintenanceDue: auto
> projectSize: auto
> sizeStrategy: auto
> 生成后改为 GENERATED；只有 GENERATED 才能作为快速恢复入口。TEMPLATE_PLACEHOLDER 只能说明项目尚未完成业务摘要生成。
> 来源：由 `business-rules.md` 和 `project-map.md` 浓缩生成；业务规则变更时同步更新。
## 项目定位
- 一句话定位：（待生成）
- 项目类型：（待生成）
- 项目规模：auto
- 规模策略：auto
- 主要入口：（待生成）
## 核心业务域（≤5 个）
| 业务域 | 一句话说明 | 涉及模块 |
|---|---|---|
| （待填充） |  |  |
## 关键不变量（≤5 条）
- （待填充）
## 动态上下文门禁
| 任务等级 | 默认读取 | 升级条件 |
|---|---|---|
| L0 状态确认/简单问答 | 仅本文件 | 定位不清时读 `business/project-map.md` |
| L1 机械/文案/样式小改 | 本文件 + 命中文件片段 | 影响行为时升 L2 |
| L2 简单代码改动 | 本文件 + `core-lite/delivery-lite.md` + 相关源码 | 涉及安全/测试时加对应 core-lite |
| L3 边界实际变更 | 先搜索命中规则 + 相关 contracts/core | 公开契约/鉴权/迁移/敏感数据改变 |
| L4 接入/审计/重构 | `AI-START.md` + 必要规范 | 用户明确要求完整分析 |
## 实施硬门禁（含计划自动触发门禁）
执行任何实施任务前自动判定，无需用户额外提醒：项目级/分阶段、多模块验收或跨接口/数据/权限/安全/进程边界时读 `.ai-spec/workflows/project-planning.md`；未落 `docs/plans/project-plan.md` 和 `docs/plans/current.md` 前不得改业务代码。
新增/调整模块、目录、共享抽象或跨模块调用时读 `.ai-spec/core/architecture.md`，检查 `docs/architecture/modules.md`；缺失则用 `.ai-spec/governance/module-contract-template.md` 建最小模块契约。
改 API/DTO/DB/权限/页面/进程/外部系统时，在计划或阶段验收填写影响矩阵；涉及核心链路时检查 `docs/quality/regression-checklist.md`，缺失则用 `.ai-spec/governance/regression-checklist-template.md` 建最小回归清单。
