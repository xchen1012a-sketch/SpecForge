# SpecForge

SpecForge 是一套面向真实软件项目的 AI 协作规范模板。它的目标不是让 AI 每次从头读完整项目，而是让 AI 按项目规模、任务风险和当前目标动态加载最小必要上下文。

核心定位：

- 给 Claude Code、Codex、Cursor、Copilot、Windsurf、Cline、Aider、Gemini 等 AI 工具提供统一启动协议
- 让新项目、老项目、开发中项目都能接入同一套工程规范
- 用 `quick-ref + project-map + core-lite + 按需升级` 控制 token 消耗
- 把安全、测试、交付、API 契约、业务规则沉淀成可执行规范
- 默认安全：先只读识别，再 dry-run，再实施，不覆盖用户已有内容

## 为什么需要 SpecForge

普通 AI 项目规范容易出现两个极端：

1. 规范太少：AI 不知道项目边界、业务规则、安全红线，容易乱改。
2. 规范太重：AI 每次小改动都读完整文档和完整项目，token 浪费严重。

SpecForge 解决的是第二种问题：规范要完整，但加载必须动态。

日常会话默认只读轻量入口；只有任务变复杂、风险升高、涉及跨端/API/权限/数据时，才加载更重的规范文件。

## 动态省 token 机制

SpecForge 的上下文加载分三层控制。

### 1. 日常唯一入口

已接入项目的普通会话优先读取：

```text
business/quick-ref.md
```

`quick-ref.md` 是约 30-40 行的项目速查卡。它只包含项目身份、启动命令、关键目录、核心业务规则、风险点和当前项目规模。

只有当状态为：

```text
状态: GENERATED
```

AI 才允许把它当作真实项目事实使用。模板占位状态不会被误读。

### 2. 按任务风险加载

SpecForge 使用 L0-L4 上下文预算：

| 等级 | 适用场景 | 默认读取范围 |
| --- | --- | --- |
| L0 | 快速恢复、状态确认 | `quick-ref.md` |
| L1 | 文案、样式、局部机械改动 | `quick-ref.md` + 精确目标文件 |
| L2 | 普通功能改动 | `quick-ref.md` + `project-map.md` + `core-lite/` |
| L3 | API、权限、数据、跨端、高风险改动 | 相关 `core/`、`contracts/`、`stacks/` 按需加载 |
| L4 | 首次接入、审计、重构规划 | 允许完整扫描，但必须说明原因 |

### 3. 按项目大小匹配

安装器会根据文件数、构建文件、API、数据库、鉴权、CI、多项目结构等信号写入：

```yaml
context:
  projectSize: auto
  preferLiteCore: true
  dynamicRouting: true
  allowFullScanByDefault: false
```

运行时按项目规模选择策略：

| 项目大小 | 策略 |
| --- | --- |
| tiny | 只读 quick-ref 和精确文件，默认不读完整 core |
| small | 优先 core-lite，按需读 project-map |
| medium | quick-ref + project-map + 相关模块 |
| large | 先定位模块，再加载局部规范 |
| enterprise | 必须有 project-map、契约、治理和例外机制 |

## 核心能力

- **动态上下文路由**：按任务级别和项目规模决定读取范围。
- **轻量核心规范**：`core-lite/` 覆盖简单改动，不让小任务加载完整交付/安全/测试规范。
- **完整工程规范**：高风险任务按需加载 `core/`、`contracts/`、`stacks/`。
- **业务规则裁剪**：接入时根据项目结构裁掉无 API、无 KPI、无外部系统等空章节。
- **多项目接入**：识别仓库下多个子项目，为每个子项目生成独立 `.ai-spec/`。
- **安全安装器**：默认只复制缺失文件，不覆盖已有配置。
- **Git 提交硬门禁**：提交前必须检查暂存区，只提交源码、测试、迁移、锁文件、文档等纯代码资产，过滤 `.env`、IDE 配置、本地设置、构建产物和真实凭证。
- **确定性验证**：模板结构、Markdown 链接、Skill 格式、安装器行为都有测试。

## 快速安装

### 方式一：直接克隆到项目

在目标项目根目录执行：

PowerShell：

```powershell
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec; Remove-Item -Recurse -Force .ai-spec/.git
```

Bash：

```bash
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec && rm -rf .ai-spec/.git
```

然后对 AI 说：

```text
请读取 .ai-spec/AI-START.md，并严格按启动协议接入当前项目。先完成只读识别和启动报告，不要直接修改业务代码。
```

### 方式二：使用安装器

默认模式是安全复制：只补缺失文件，不覆盖已有入口或项目配置。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -TargetRoot <项目目录> -Tools codex -Apply
```

完整接入模式使用 `-Onboard`：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -TargetRoot <项目目录> -Tools codex -Onboard -Apply
```

它会执行：

- 项目类型识别
- 项目规模识别
- 多项目识别
- `.specforge.json` 生成
- `quick-ref.md` 初始化
- `business-rules.md` 动态裁剪
- 无关 stacks/adapters/core 规范瘦身

Git 分支和初始基线 commit 属于有状态操作，必须显式开启：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -TargetRoot <项目目录> -Tools codex -Onboard -ManageGit -Apply
```

## 启动方式

如果 SpecForge 安装在项目的 `.ai-spec/` 目录：

```text
请读取 .ai-spec/AI-START.md，并严格按启动协议执行。
```

如果当前仓库本身就是 SpecForge：

```text
请读取 AI-START.md，并严格按启动协议执行。
```

已接入项目的普通日常会话，AI 应优先使用：

```text
business/quick-ref.md
```

除非 quick-ref 不是 `GENERATED`，或者任务明确需要接入、审计、重构、跨端/API/权限/数据等高风险上下文。

## 目录结构

```text
.
├── AI-START.md                  # 任意 AI 的唯一强制启动入口
├── README.md                    # GitHub 首页说明
├── ai-spec.example.yaml         # 项目画像和动态上下文配置示例
├── adapters/                    # AI 工具适配器
├── business/                    # quick-ref、project-map、business-rules
├── contracts/                   # API 与跨端契约
├── core/                        # 完整工程规范
├── core-lite/                   # 简单任务轻量规范
├── docs/                        # 使用指南和历史资料
├── governance/                  # 规则分级、例外、ADR、RFC、风险登记
├── scripts/                     # 安装与验证脚本
├── skills/                      # 标准 Agent Skill
├── stacks/                      # 技术栈专项规范
├── tests/                       # 模板自身测试
└── workflows/                   # 新项目、老项目、开发中项目接入流程
```

## 验证

在 SpecForge 仓库根目录执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate.ps1
```

验证内容包括：

- 模板必需文件是否存在
- Markdown 链接是否有效
- AI Skill frontmatter 是否合规
- 动态路由 frontmatter 是否唯一
- 安装器是否不覆盖已有文件
- `-Onboard` 是否能生成 quick-ref、projectSize、`.specforge.json`
- Git 提交硬门禁是否存在

## 提交安全规则

SpecForge 明确要求：提交前必须检查暂存区，不能直接无差别 `git add -A`。

允许提交：

- 源码
- 测试
- 文档
- 迁移文件
- 锁文件
- 模板配置示例

默认过滤：

- `.env`
- IDE 配置
- 本地设置
- 构建产物
- 临时文件
- 真实密钥、token、密码、凭证

CI 配置文件可以提交，但不能包含密钥。

## 适用范围

适合：

- 希望多个 AI 工具共享同一套项目规范
- 希望 AI 接手老项目时先建模再修改
- 希望降低小改动的 token 消耗
- 希望团队沉淀安全、测试、交付、业务规则
- 希望 AI 协作过程可审计、可回滚、可治理

不适合：

- 只想要一个极简 prompt
- 不希望项目里出现任何规范目录
- 不接受 AI 在修改前先做只读识别

## 详细文档

更多说明见：

- [使用指南](docs/使用指南.md)
- [AI-START.md](AI-START.md)
- [ai-spec.example.yaml](ai-spec.example.yaml)

