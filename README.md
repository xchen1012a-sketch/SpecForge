# SpecForge

一套面向企业级软件开发的、工具无关的 AI 协作规范。它通过单一入口启动，通过模块化规则适配不同项目，通过工具适配器兼容不同 AI 开发软件。

## 最快启动

### 一行命令导入到项目

在目标项目根目录打开终端，执行（任选其一）：

PowerShell（Windows）：

```powershell
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec; Remove-Item -Recurse -Force .ai-spec/.git
```

Bash（macOS / Linux / Git Bash）：

```bash
git clone https://github.com/xchen1012a-sketch/SpecForge.git .ai-spec && rm -rf .ai-spec/.git
```

`.ai-spec/` 已存在时会报错，需先删或换名。

### 启动 AI

把本目录放到项目根目录的 `.ai-spec/`，然后对任意能读取项目文件的 AI 说：

```text
请读取 .ai-spec/AI-START.md，并严格按启动协议接入当前项目。先完成只读识别和启动报告，不要直接修改业务代码。
```

如果本目录就是项目根目录，则改为：

```text
请读取 AI-START.md，并严格按启动协议执行。
```

`AI-START.md` 是唯一强制入口。Claude Code、Codex、Cursor、Copilot、Windsurf、Cline、Aider、Gemini 以及其它能读取 Markdown 的 AI 都可以使用。工具专属适配器只负责自动发现和提升体验，不复制规范正文。

## 设计原则

- **单一入口**：所有 AI 都先读 `AI-START.md`。
- **通用内核**：安全、架构、测试、交付等规则不绑定工具。
- **按需加载**：根据任务读取相关模块，避免把全部规则塞进上下文。
- **项目分型**：新项目、老项目、开发中项目走不同接入流程。
- **安全默认**：先只读识别，再 dry-run，再实施；不覆盖用户已有内容。
- **确定性验证**：文件结构、断链、权限和 Skill 格式由脚本检查。
- **可治理**：规则分为 MUST、SHOULD、MAY、PROJECT 和 EXCEPTION。

## 核心特性

- **多 AI 并行协作**：§1.7 定义了基于 session 的文件锁定协议，多个 AI 同时工作不冲突
- **动态多项目支持**：§1.5.1 自动检测子项目结构，为每个子项目独立安装规范实例，UUID 共享身份
- **日常速查卡**：`business/quick-ref.md` 从完整业务规则中自动浓缩 30 行摘要，减少上下文消耗
- **技术栈动态适配**：根据项目类型自动保留相关 stacks/ 规范，删除无关文件
- **实时业务规则维护**：§1.6 单文件活文档，带来源标注、可靠度、冲突标记

## 目录

```text
.
├── AI-START.md                 # 任意 AI 的唯一启动入口
├── README.md                   # 给人看的项目说明
├── AI双工具全栈开发操作手册.md    # 全栈多仓库协作操作指南
├── ai-spec.example.yaml        # 项目画像配置示例
├── adapters/                   # AI 工具自动发现适配器
├── business/                   # 项目业务规则
├── contracts/                  # API 与跨端契约
├── core/                       # 通用工程规范内核
├── docs/                       # 使用说明和 V1 历史资料
├── governance/                 # 规则分级、例外和治理模板
├── scripts/                    # 安装与验证脚本
├── skills/                     # 标准 Agent Skill
├── stacks/                     # 技术栈专项规范
├── tests/                      # 模板自身测试
└── workflows/                  # 新/老/开发中项目接入流程
```

## 验证模板

Windows PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate.ps1
```

详细使用方式见 [docs/使用指南.md](docs/使用指南.md)。

## 边界

本模板可以为任何能读取 Markdown 的 AI 提供统一规范，但不同工具的自动发现文件、权限模型和 Skill 路径会变化。`adapters/` 负责版本适配；未知工具始终回退到直接读取 `AI-START.md`。

