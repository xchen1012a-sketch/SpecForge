# SpecForge

SpecForge 是一套 AI 项目协作规范模板，核心目标是：**让 AI 按需读取上下文，而不是每次小改动都从头读完整项目。**

SpecForge 只安装到当前项目，不会写入 `~/.claude/rules/`、`~/.codex/` 等用户全局配置；全局规则不受项目动态门禁控制，只做只读审计提醒。

它适合 Claude Code、Codex、Cursor、Copilot 等工具；Windsurf/Cline/Aider/Gemini 通过 adapters/generic 通用入口使用。

## 核心亮点

- **动态省 token**：日常优先读 `business/quick-ref.md`，复杂任务才升级读取更多规范。
- **按任务风险加载**：L0-L4 控制上下文范围，小改动不加载完整规范。
- **按项目大小匹配**：tiny / small / medium / large / enterprise 自动选择加载策略。
- **自动项目画像**：首次接入时扫描代码、构建、依赖和文档，直接生成 `ai-spec.yaml`。
- **轻量核心规范**：`core-lite/` 处理简单任务，避免常驻大文档。
- **完整工程约束**：高风险任务按需加载 `core/`、`contracts/`、`stacks/`。
- **接入时自动瘦身**：根据项目结构裁剪业务规则、技术栈规范和无关章节。
- **多项目版本同步**：父目录 `.specforge.json` 和子项目 `ai-spec.yaml` 记录 `templateVersion`，通过项目内更新器同步核心规范。
- **安全提交门禁**：提交前必须检查暂存区，过滤 `.env`、IDE 配置、本地设置、构建产物和真实凭证。
- **五个核心 Skill**：产品方案、开发实施、代码审查、问题诊断、规范评估。
- **Skill 策略可切换**：默认 `project-first`；用户可改为 `local-first` 或 `hybrid`，决定项目 Skill、本地 Skill 或两者兼顾。
- **阶段化计划**：复杂任务自动触发，长计划落盘到 `docs/plans/`，日常只读取当前阶段。

## 动态加载策略

| 场景 | 默认读取 |
| --- | --- |
| 快速恢复 / 状态确认 | `quick-ref.md` |
| 文案、样式、局部小改 | `quick-ref.md` + 目标文件 |
| 普通功能改动 | `quick-ref.md` + `core-lite/` + 相关源码 |
| 公开契约 / 权限边界 / 迁移 / 敏感数据 | 按需加载 `core/`、`contracts/`、`stacks/` |
| 首次接入 / 审计 / 重构规划 | 允许完整扫描，但必须说明原因 |

## before/after

不用 SpecForge：AI 容易先全量扫项目，再输出长篇、不聚焦的报告。

使用 SpecForge：AI 先读 `quick-ref.md`；缺失时才进入接入流程，只问必要确认项，并按输出协议给短版结论。

## 能力边界

SpecForge 是项目级协作规范，不是模型行为的绝对保证。它通过 quick-ref、动态门禁、验证脚本、交付报告和 Git diff 提高可审计性；高风险改动仍需要人工 review。

约束分三层：工具权限负责拦危险文件/命令，验证脚本负责结构和门禁，AI 负责报告读取范围、升级原因和未证实项。

首次接入、审计、重构规划会比日常任务重，因为 AI 需要建立项目画像。接入完成后，普通会话应优先走 `quick-ref.md`，按证据逐级加载，不应每次全量扫描。

默认输出简体中文；只有用户明确要求时，才允许当前任务或当前项目切换到其它语言。

## 快速安装

在目标项目根目录执行：

PowerShell：

```powershell
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec; Remove-Item -Recurse -Force .ai-spec/.git
```

CMD：

```bat
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec && rmdir /s /q .ai-spec\.git
```

Bash：

```bash
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec && rm -rf .ai-spec/.git
```

安装完成后，不需要手动跑额外脚本；直接把下面的首次接入提示词发给 AI，让 AI 按规范完成项目画像、动态瘦身和入口文件生成。

### 首次接入提示词

```text
请读取 .ai-spec/AI-START.md，并严格按启动协议接入当前项目。先完成只读识别和启动报告，不要直接修改业务代码。
```

## 切换 AI 提示词

项目已经接入 SpecForge 时，对新 AI 说：

```text
当前项目已经完成 SpecForge 接入，不要重新安装、重新接入或全量扫描。请先读取 .ai-spec/business/quick-ref.md，按动态上下文门禁加载必要文件；检查 git status、docs/plans/current.md、最新 Handoff 和 active session。先简要报告当前阶段、未完成事项、工作区状态和下一步，确认没有文件冲突后继续。
```

正在开发中的任务，最好把具体的 `docs/handoffs/<文件名>.md` 一并告诉新 AI；缺少 Handoff 时，新 AI 应根据 Git 状态和当前阶段计划恢复，不得假装继承了上一段对话记忆。

## 规范更新或重新拉取提示词

已有 `.ai-spec/` 时不要删除整个目录，也不要直接 `git clone` 覆盖。下面两个更新器会拉取最新版并安全同步，默认只预览；确认后增加 `-Apply`：

PowerShell：

```powershell
.\.ai-spec\scripts\update.ps1
.\.ai-spec\scripts\update.ps1 -Apply
```

CMD：

```bat
.ai-spec\scripts\update.cmd
.ai-spec\scripts\update.cmd -Apply
```

Bash：

```bash
bash .ai-spec/scripts/update.sh
bash .ai-spec/scripts/update.sh --apply
```

更新完成后对 AI 说：

```text
当前项目之前已经完成 SpecForge 接入，本次只是恢复或更新规范，不是首次接入。不要重新全量扫描项目，不要覆盖 ai-spec.yaml、business/、docs/plans/、docs/handoffs/ 和已有 AI 入口。先读取 status 为 GENERATED 的 quick-ref、当前计划和 Git 状态，只补充缺失规范；如果项目状态文件也被删除，先报告缺失项，再做最小范围增量重建。默认使用简体中文。
```

## 上下文惰性维护

AI 日常只检查 quick-ref 中一行 `maintenanceDue`；未到期不扫描。到期后按项目规模执行 dry-run，确认后只归档明确 completed 的安全对象：

```powershell
.\.ai-spec\scripts\maintain-context.ps1
.\.ai-spec\scripts\maintain-context.ps1 -Apply
```

Bash：

```bash
bash .ai-spec/scripts/maintain-context.sh
bash .ai-spec/scripts/maintain-context.sh --apply
```

tiny/small 每 30 天、medium 每 14 天、large/enterprise 每 7 天检查一次。业务规则、活动计划、验收证据和源码不会被自动删除；臃肿语义文件只报告并按工作流做可回滚拆分。

检查 Claude 全局常驻规则是否绕过项目动态门禁（只读，不修改）：

```powershell
.\.ai-spec\scripts\audit-global-context.ps1
```

## 验证

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate.ps1
```

验证覆盖结构、链接、Skill 格式、动态路由 frontmatter、快速安装产物、更新同步和 Git 提交门禁。

## 详细文档

- [AI-START.md](AI-START.md)
- [使用指南](docs/使用指南.md)
- [配置示例](ai-spec.example.yaml)
