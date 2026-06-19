# 多项目接入工作流

仅当 `PROJECT_ROOT` 下检测到 2+ 个真实项目目录时读取本文件。父目录通常不是代码项目，不放完整 `.ai-spec/`。

## 1. 先排除同项目多副本

检测到多个候选项目时，不要立即按多项目安装。先判断是否为同项目多副本：

- 子目录名称表达版本/用途：`全版工程代码`、`授课工程代码`、`demo`、`backup`、`copy`、`archive`
- 多个子目录存在同名包结构、同名主入口、相同 `src/` 层级
- 构建文件类型相同，依赖高度相似
- Java/Eclipse 项目出现相同 `.project` / `.classpath` / 包名

命中上述信号时，输出“疑似同项目多副本”，询问用户选择：

1. 按单项目处理，选择一个主目录接入。
2. 按多项目处理，每个子项目独立 `.ai-spec/`。
3. 只生成分析报告，不安装。

未确认前不得批量写入多个 `.ai-spec/`。

## 2. 安装规则

1. 每个真实子项目各安装一份 `.ai-spec/`。
2. 所有实例共享一个 `multiProjectId`，写入各自 `ai-spec.yaml`。
3. 父目录只创建 `.specforge.json` 轻量索引：

```json
{
  "templateSource": "SpecForge",
  "templateVersion": 2,
  "multiProjectId": "<uuid>",
  "projects": [
    {
      "path": "frontend",
      "type": "frontend",
      "buildFiles": ["package.json"],
      "installedAt": "<ISO timestamp>"
    }
  ]
}
```

## 3. 一致文件与差异文件

所有实例中应保持一致：

- `AI-START.md`
- `README.md`
- `core/`
- `core-lite/`
- `governance/`
- `skills/`
- `workflows/`
- `contracts/`
- `scripts/validate.ps1`

每个项目独立维护，禁止同步覆盖：

- `ai-spec.yaml`
- `ai-spec.yaml.draft`
- `business/`
- `stacks/`
- `adapters/`

## 4. ai-spec.yaml.draft

如果正式 `ai-spec.yaml` 已存在或 AI 没有用户确认，不得覆盖正式文件。

允许生成：

```text
.ai-spec/ai-spec.yaml.draft
```

draft 只表达 AI 推断的项目画像。用户确认后再手动改名或合并到正式 `ai-spec.yaml`。

## 5. 项目类型判定

| 信号 | 类型 |
| --- | --- |
| `package.json` 且依赖含 React / Vue / Next.js 等前端框架 | `frontend` |
| `pom.xml` / `go.mod` / `requirements.txt` / `.project` / `.classpath` 且无前端框架依赖 | `backend` |
| `package.json` 同时含前端框架和后端框架依赖 | `fullstack` |
| `pubspec.yaml` / 含 `android/` 或 `ios/` 目录 | `mobile` |
| `Cargo.toml` / `go.mod` 且无 Web 服务框架 | `library-sdk` |
| `pyproject.toml` 且含 AI/LLM 框架依赖 | `ai-llm` |
| 含 `main.go` / `main.rs` / `__main__.py` / `bin/` 目录，且无 Web 框架依赖 | `cli` |
| 含 `dbt_project.yml` / `airflow.cfg` / `dagster` / 大量 SQL 文件，且无 Web 入口 | `data-platform` |
| 无法判定 | `generic` |

L4 接入允许检查深度 ≤ 2 的候选目录，但必须排除 `node_modules`、`vendor`、`.git`、`dist`、`build`、`target`、`out`。

## 6. 后续会话

- 子项目目录启动：按普通启动协议执行，使用 `multiProjectId` 识别兄弟项目。
- 父目录启动：读取 `.specforge.json` 后询问本次处理哪个子项目或全部。
- 版本不一致：提示执行 `scripts/install.ps1 -TargetRoot <父目录或项目目录> -Sync`；实际覆盖必须由用户确认并追加 `-Apply`。

