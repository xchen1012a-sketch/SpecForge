$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $script:failures.Add($Message) }
}

function Read-ProjectFile {
    param([string]$RelativePath)
    $path = Join-Path $root $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $script:failures.Add("Missing file: $RelativePath")
        return ''
    }
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path
}

$requiredFiles = @(
    'AI-START.md',
    'README.md',
    '.gitattributes',
    'ai-spec.example.yaml',
    'adapters/README.md',
    'adapters/claude-code/CLAUDE.md.template',
    'adapters/claude-code/settings.json.template',
    'adapters/codex/AGENTS.md.template',
    'adapters/cursor/ai-spec.mdc.template',
    'adapters/github-copilot/copilot-instructions.md.template',
    'adapters/generic/START-PROMPT.md',
    'business/quick-ref.md',
    'core-lite/delivery-lite.md',
    'core-lite/security-lite.md',
    'core-lite/testing-lite.md',
    'core/command-standard.md',
    'workflows/multi-project-onboard.md',
    'workflows/output-protocol.md',
    'workflows/new-project.md',
    'workflows/existing-project.md',
    'workflows/in-progress-project.md',
    'governance/policy-levels.md',
    'governance/exception-template.md',
    'governance/adr-template.md',
    'governance/rfc-template.md',
    'governance/risk-register-template.md',
    'governance/handoff-template.md',
    'governance/ownership-template.md',
    'skills/product-architect/SKILL.md',
    'skills/dev-implementation/SKILL.md',
    'skills/code-reviewer/SKILL.md',
    'skills/debugger/SKILL.md',
    'skills/spec-evaluator/SKILL.md',
    'scripts/install.sh',
    'scripts/install.ps1',
    'scripts/validate.ps1'
)

foreach ($relativePath in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) "Missing file: $relativePath"
}

# Root .md whitelist: AI-START.md, README.md, and any manual with prefix "AI"
$rootMarkdown = @(Get-ChildItem -LiteralPath $root -File -Filter '*.md' | Select-Object -ExpandProperty Name)
$allowedRootMarkdown = @('AI-START.md', 'README.md')
$unexpectedRootMarkdown = @($rootMarkdown | Where-Object {
    $_ -notin $allowedRootMarkdown -and $_ -notmatch '^AI.*\.md$'
})
Assert-True ($unexpectedRootMarkdown.Count -eq 0) "Unexpected root Markdown: $($unexpectedRootMarkdown -join ', ')"

$start = Read-ProjectFile 'AI-START.md'
foreach ($section in @('Startup Protocol', 'Project Stage Detection', 'AI Tool Detection', 'Security Baseline', 'Context Routing', 'Delivery Protocol')) {
    Assert-True ($start.Contains($section)) "AI-START.md missing section marker: $section"
}
Assert-True ($start.Contains('new-project')) 'AI-START.md does not route new projects'
Assert-True ($start.Contains('existing-project')) 'AI-START.md does not route existing projects'
Assert-True ($start.Contains('in-progress-project')) 'AI-START.md does not route in-progress projects'
Assert-True ($start.Contains('generic')) 'AI-START.md has no generic fallback'
Assert-True ($start.Contains('上下文预算')) 'AI-START.md missing context budget protocol'
Assert-True ($start.Contains('状态: GENERATED')) 'AI-START.md quick recovery does not require generated quick-ref status'
Assert-True ($start.Contains('上下文使用报告')) 'AI-START.md does not require context usage reporting'
Assert-True ($start.Contains('受控例外')) 'AI-START.md does not define controlled exceptions'
Assert-True ($start.Contains('初始基线 commit')) 'AI-START.md does not clarify the no-Git initial commit exception'
Assert-True ($start.Contains('quick-ref.md 是日常启动唯一入口')) 'AI-START.md does not make quick-ref the daily startup entry'
Assert-True ($start.Contains('core-lite/delivery-lite.md')) 'AI-START.md does not route simple tasks to core-lite'
Assert-True ($start.Contains('projectSize')) 'AI-START.md missing project size routing'
Assert-True ($start.Contains('tiny | small | medium | large | enterprise')) 'AI-START.md missing project size levels'
Assert-True ($start.Contains('Git 提交硬性门禁')) 'AI-START.md missing hard git commit gate'
Assert-True ($start.Contains('只提交纯代码')) 'AI-START.md missing pure-code commit rule'
Assert-True ($start.Contains('暂存区必须检查')) 'AI-START.md missing staging-area check rule'
Assert-True ($start.Contains('先澄清假设')) 'AI-START.md missing clarify-assumptions coding discipline'
Assert-True ($start.Contains('简单优先')) 'AI-START.md missing simplicity-first coding discipline'
Assert-True ($start.Contains('外科式改动')) 'AI-START.md missing surgical-change coding discipline'
Assert-True ($start.Contains('目标驱动验证')) 'AI-START.md missing goal-driven verification discipline'
Assert-True ($start.Contains('workflows/multi-project-onboard.md')) 'AI-START.md missing lazy multi-project workflow route'
Assert-True ($start.Contains('workflows/output-protocol.md')) 'AI-START.md missing output protocol route'
Assert-True ($start.Contains('workflows/session-coordination.md')) 'AI-START.md missing session coordination workflow route'
Assert-True ($start.Contains('Skill 使用策略')) 'AI-START.md missing skill policy section'
Assert-True ($start.Contains('project-first')) 'AI-START.md missing project-first skill mode'
Assert-True ($start.Contains('local-first')) 'AI-START.md missing local-first skill mode'
Assert-True ($start.Contains('hybrid')) 'AI-START.md missing hybrid skill mode'
foreach ($skillName in @('product-architect', 'dev-implementation', 'code-reviewer', 'debugger', 'spec-evaluator')) {
    Assert-True ($start.Contains("skills/$skillName/SKILL.md")) "AI-START.md missing skill route: $skillName"
}
foreach ($mode in @('L0 快速恢复', 'L1 机械改动', 'L2 标准改动', 'L3 高风险改动', 'L4 接入/审计')) {
    Assert-True ($start.Contains($mode)) "AI-START.md missing context budget mode: $mode"
}

$quickRef = Read-ProjectFile 'business/quick-ref.md'
Assert-True ($quickRef.Contains('状态: TEMPLATE_PLACEHOLDER')) 'quick-ref.md missing placeholder status marker'
Assert-True ($quickRef.Contains('生成后改为 GENERATED')) 'quick-ref.md does not explain generated status transition'
Assert-True ($quickRef.Contains('动态上下文门禁')) 'quick-ref.md missing dynamic context gate'
Assert-True ($quickRef.Contains('日常启动唯一入口')) 'quick-ref.md is not documented as the daily startup entry'
Assert-True ($quickRef.Contains('projectSize:')) 'quick-ref.md missing project size marker'
Assert-True ($quickRef.Contains('sizeStrategy:')) 'quick-ref.md missing size-based loading strategy marker'

foreach ($lite in @('core-lite/delivery-lite.md', 'core-lite/security-lite.md', 'core-lite/testing-lite.md')) {
    $liteContent = Read-ProjectFile $lite
    Assert-True ($liteContent.Contains('appliesTo:')) "$lite missing appliesTo frontmatter"
    Assert-True ($liteContent.Contains('loadWhen:')) "$lite missing loadWhen frontmatter"
}

$deliveryLite = Read-ProjectFile 'core-lite/delivery-lite.md'
Assert-True ($deliveryLite.Contains('短版输出')) 'delivery-lite missing short output rule'
Assert-True ($deliveryLite.Contains('禁止流水账')) 'delivery-lite missing no-process-log rule'
Assert-True ($deliveryLite.Contains('表格最多 3 列')) 'delivery-lite missing narrow-table rule'

$outputProtocol = Read-ProjectFile 'workflows/output-protocol.md'
Assert-True ($outputProtocol.Contains('默认短版')) 'output protocol missing short-by-default rule'
Assert-True ($outputProtocol.Contains('L0')) 'output protocol missing level-based output rules'
Assert-True ($outputProtocol.Contains('终端友好表格')) 'output protocol missing terminal-friendly table rules'
Assert-True ($outputProtocol.Contains('表格最多 3 列')) 'output protocol missing max table column rule'
Assert-True ($outputProtocol.Contains('风险清单优先用编号列表')) 'output protocol missing numbered risk list rule'

$sessionWorkflow = Read-ProjectFile 'workflows/session-coordination.md'
Assert-True ($sessionWorkflow.Contains('工具不会自动执行锁')) 'session workflow missing non-automatic-lock warning'
Assert-True ($sessionWorkflow.Contains('workflows/session-coordination.md')) 'session workflow missing self route marker'

$multiProjectWorkflow = Read-ProjectFile 'workflows/multi-project-onboard.md'
Assert-True ($multiProjectWorkflow.Contains('同项目多副本')) 'multi-project workflow missing duplicate-copy guard'
Assert-True ($multiProjectWorkflow.Contains('AI 首次接入直接生成')) 'multi-project workflow missing direct ai-spec generation guidance'
Assert-True ($multiProjectWorkflow.Contains('templateVersion')) 'multi-project workflow missing template version consistency rule'
Assert-True ($multiProjectWorkflow.Contains('install.ps1 -TargetRoot')) 'multi-project workflow missing sync command rule'
Assert-True ($multiProjectWorkflow.Contains('禁止同步覆盖')) 'multi-project workflow missing no-automatic-sync-overwrite rule'

$validateScript = Read-ProjectFile 'scripts/validate.ps1'
Assert-True ($validateScript.Contains('Conflict summary')) 'validate.ps1 missing conflict summary output'

$specExample = Read-ProjectFile 'ai-spec.example.yaml'
Assert-True ($specExample.Contains('context:')) 'ai-spec.example.yaml missing context configuration'
Assert-True ($specExample.Contains('projectSize: auto')) 'ai-spec.example.yaml missing project size default'
Assert-True ($specExample.Contains('projectSizeSignals:')) 'ai-spec.example.yaml missing project size signals'
Assert-True ($specExample.Contains('generated by installer')) 'ai-spec.example.yaml does not mark generated signals'
Assert-True ($specExample.Contains('quickRefStatus: TEMPLATE_PLACEHOLDER')) 'ai-spec.example.yaml missing quick-ref status default'
Assert-True ($specExample.Contains('skillPolicy:')) 'ai-spec.example.yaml missing skill policy'
Assert-True ($specExample.Contains('mode: project-first')) 'ai-spec.example.yaml missing default project-first skill policy'

$readme = Read-ProjectFile 'README.md'
Assert-True ($readme.Contains('Windsurf/Cline/Aider/Gemini 通过 adapters/generic')) 'README missing generic adapter clarification'
Assert-True ($readme.Contains('before/after')) 'README missing before/after example'
Assert-True ($readme.Contains('五个核心 Skill')) 'README missing five core skills note'

$adapterReadme = Read-ProjectFile 'adapters/README.md'
Assert-True ($adapterReadme.Contains('project-first')) 'adapters README missing project-first skill policy'
Assert-True ($adapterReadme.Contains('local-first')) 'adapters README missing local-first skill policy'
Assert-True ($adapterReadme.Contains('hybrid')) 'adapters README missing hybrid skill policy'

$installSh = Read-ProjectFile 'scripts/install.sh'
Assert-True ($installSh.Contains('--onboard')) 'install.sh missing onboard option'
Assert-True ($installSh.Contains('--sync')) 'install.sh missing sync option'

$gitAttributes = Read-ProjectFile '.gitattributes'
Assert-True ($gitAttributes.Contains('*.sh text eol=lf')) '.gitattributes does not force LF for shell scripts'

Assert-True ($start.Contains('AI 首次接入必须') -and $start.Contains('ai-spec.yaml')) 'AI-START.md does not allow AI to generate ai-spec.yaml on onboarding'
Assert-True ($start.Contains('后续修改需用户明确授权')) 'AI-START.md missing explicit authorization rule for later ai-spec edits'

foreach ($routedFile in @(
    'core/delivery-standard.md',
    'core/security-standard.md',
    'core/testing-standard.md',
    'contracts/api-contract-standard.md',
    'contracts/integration-standard.md',
    'stacks/frontend-general.md',
    'stacks/backend-general.md'
)) {
    $routedContent = Read-ProjectFile $routedFile
    $normalizedRoutedContent = $routedContent.TrimStart([char]0xFEFF, [char]0x200B, " ", "`r", "`n", "`t")
    Assert-True ($normalizedRoutedContent.StartsWith('---')) "$routedFile missing routing frontmatter"
    Assert-True ($routedContent.Contains('appliesTo:')) "$routedFile missing appliesTo frontmatter"
    Assert-True ($routedContent.Contains('loadWhen:')) "$routedFile missing loadWhen frontmatter"
    Assert-True (([regex]::Matches($routedContent, '(?m)^appliesTo:')).Count -eq 1) "$routedFile has duplicate appliesTo frontmatter"
    Assert-True (([regex]::Matches($routedContent, '(?m)^loadWhen:')).Count -eq 1) "$routedFile has duplicate loadWhen frontmatter"
    Assert-True (([regex]::Matches($routedContent, '(?m)^fallbackTo:')).Count -eq 1) "$routedFile has duplicate fallbackTo frontmatter"
}

$securityStandard = Read-ProjectFile 'core/security-standard.md'
Assert-True ($securityStandard.Contains('Git 提交硬性门禁')) 'security standard missing hard git commit gate'
Assert-True ($securityStandard.Contains('暂存区必须检查')) 'security standard missing staging-area check'
Assert-True ($securityStandard.Contains('只提交纯代码')) 'security standard missing pure-code commit rule'
Assert-True ($securityStandard.Contains('.env')) 'security standard missing env-file filter'
Assert-True ($securityStandard.Contains('IDE 配置')) 'security standard missing IDE config filter'
Assert-True ($securityStandard.Contains('构建产物')) 'security standard missing build artifact filter'

foreach ($skill in @('product-architect', 'dev-implementation', 'code-reviewer', 'debugger', 'spec-evaluator')) {
    $relativePath = "skills/$skill/SKILL.md"
    $content = Read-ProjectFile $relativePath
    Assert-True ($content -match "(?ms)^---\s*\nname:\s*$skill\s*\ndescription:") "$relativePath has invalid frontmatter"
    Assert-True (-not ($content -match '(?m)^trigger:')) "$relativePath uses non-standard trigger field"
}

$settings = Read-ProjectFile 'adapters/claude-code/settings.json.template'
foreach ($dangerousRule in @(
    'Bash(npm *)', 'Bash(pip *)', 'Bash(python *)', 'Bash(docker *)',
    'Bash(curl *)', 'Bash(redis-cli *)', 'Bash(git checkout *)'
)) {
    Assert-True (-not $settings.Contains($dangerousRule)) "Unsafe default Claude permission: $dangerousRule"
}

$activeTextFiles = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.Extension -in @('.md', '.template', '.json', '.yaml', '.yml') -and
        $_.FullName -notmatch '[\\/]docs[\\/]legacy[\\/]'
    }

foreach ($file in $activeTextFiles) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    $relativePath = $file.FullName.Substring($root.Length + 1)
    Assert-True (-not $content.Contains('USAGE.md')) "$relativePath references missing USAGE.md"
    Assert-True (-not ($content -match '\.claude/skills/[^/\s`]+\.md')) "$relativePath uses a flat skill path"
    if ($relativePath -notmatch '^adapters[\\/]' -and $relativePath -notmatch '^(scripts|tests)[\\/]') {
        Assert-True (-not ($content -match '\{\{[A-Z_][A-Z0-9_]*\}\}')) "$relativePath contains an unresolved runtime placeholder"
    }
}

$integration = Read-ProjectFile 'contracts/integration-standard.md'
$passwordCodePoints = @(23494, 30721)
$passwordWord = -join ($passwordCodePoints | ForEach-Object { [char]$_ })
Assert-True (-not ($integration.Contains($passwordWord))) 'Integration standard asks for a plaintext password'

if ($failures.Count -gt 0) {
    Write-Host "V2 template tests failed: $($failures.Count)" -ForegroundColor Red
    foreach ($failure in $failures) { Write-Host "- $failure" -ForegroundColor Red }
    exit 1
}

Write-Host 'V2 template tests passed.' -ForegroundColor Green
