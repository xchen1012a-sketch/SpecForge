# 项目计划工作流

AI 必须在实施前自动判定，命中后无需用户额外提醒。触发条件：项目级或分阶段开发、预计 3 个以上实施阶段、多个模块需要分别实施验收、计划超过 200 行，或用户要求先制定完整计划。简单修改、单文件任务和普通 Bug 不生成计划文件。

若已经存在 `docs/plans/current.md`，优先恢复它指向的当前阶段；除非范围发生变化或用户要求重做计划，否则不得重新生成总计划。

## 1. 存储位置

计划属于项目状态，保存到项目的 `docs/plans/`，不保存到 `.ai-spec/`：

```text
docs/plans/
├─ project-plan.md
├─ current.md
└─ phases/
   ├─ 01-example.md
   └─ 02-example.md
```

- `docs/plans/project-plan.md`：完整项目计划和阶段基线。
- `docs/plans/current.md`：不超过 80 行的当前阶段入口，只记录当前阶段、状态、阶段文件、下一步和阻塞项。
- `docs/plans/phases/`：各阶段的实施与验收文件。

## 2. Plan Mode 到实施

1. 在 Plan Mode 或同等只读规划阶段调查现状并形成完整计划。
2. 存在重大业务或架构决策时等待用户确认；目标和方案已经明确时可直接请求执行确认。
3. 用户确认执行后，必须先保存 `docs/plans/project-plan.md`，再修改业务代码。若工具的 Plan Mode 禁止写文件，则退出 Plan Mode 后第一步完成落盘。
4. 从总计划生成当前阶段文件和 `docs/plans/current.md`，然后按阶段实施。
5. 每阶段通过验收后更新状态和验证证据，再切换 `current.md` 指向下一阶段。

## 3. 动态拆分规则

完整计划符合任一条件时自动拆分阶段文件：

- 总计划超过 200 行；
- 包含 3 个以上阶段；
- 涉及多个模块，需要分别实施和验收。

未命中时可以只保留 `project-plan.md` 和 `current.md`，不得为了形式创建空阶段文件。

## 4. 阶段内容与验收

每个阶段必须包含：阶段目标、实施范围、任务顺序、验收标准、验证命令、风险与回滚、完成状态。验收标准必须可验证，禁止只写“功能正常”或“没有问题”。

状态只使用：`planned`、`in-progress`、`blocked`、`completed`。只有验收证据已经记录时才能标记 `completed`。

## 5. 动态读取门禁

- 日常恢复只读取 `docs/plans/current.md` 和它指向的当前阶段文件，不重复读取完整总计划。
- 只有阶段切换、范围变更、依赖冲突、计划审计或恢复丢失上下文时，才读取 `docs/plans/project-plan.md`。
- 阶段文件不得静默扩大总计划范围。范围或阶段顺序变化时，同时更新总计划、阶段文件和 `current.md`。
- 计划、命令和验收证据中不得写入密码、Token 或个人敏感数据。

模板：`governance/project-plan-template.md`、`governance/phase-plan-template.md`。

路由标记：`workflows/project-planning.md`
