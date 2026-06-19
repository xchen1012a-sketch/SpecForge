---
name: spec-evaluator
description: 评估 AI 输出、项目接入过程和 SpecForge 规范本身是否符合动态上下文、输出协议、安全门禁、业务规则维护和验证要求。用于 before/after 对比、规范回归、AI 行为评分和改进建议；默认只读。
---

# SpecForge 规范评估

评估 AI 是否真正按 SpecForge 工作，而不是只复述规范。

## 启动

> 假定 AI-START.md 启动协议已完成。上下文路由按 AI-START.md 执行，本 Skill 不建立第二套路由。

1. 明确评估对象：一次 AI 输出、一次接入过程、一组规范改动或整个项目实例。
2. 读取必要证据：输出文本、diff、验证结果、quick-ref、business-rules、ai-spec.yaml、validate 输出。
3. 按规则逐项评分，不凭印象打分。
4. 只给可执行改进，不扩写愿景。

## 评估维度

- 是否按 L0-L4 和项目规模动态加载上下文。
- 是否避免宽表格、流水账和过长输出。
- 是否遵守安全、权限、Git 提交门禁。
- 是否维护 `business-rules.md` 的来源、可靠度、冲突标记。
- 是否正确处理 `quick-ref.md` 的 `GENERATED/TEMPLATE_PLACEHOLDER`。
- 是否执行真实验证并报告未验证项。
- 是否存在无关改动、过度设计或静默假设。

## 输出

```text
评分：x/10

关键问题：
1. ...

证据：
- ...

建议：
- P0 ...
- P1 ...
```

默认短输出。只在用户要求审计报告时展开。

