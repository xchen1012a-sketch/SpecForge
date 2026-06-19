$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$importPromptName = (-join (@(19968, 38190, 23548, 20837, 25552, 31034, 35789) | ForEach-Object { [char]$_ })) + '.md'
$enhancementPlanName = (-join (@(36890, 29992) | ForEach-Object { [char]$_ })) + 'AI' + (-join (@(35268, 33539, 22686, 24378, 26041, 26696) | ForEach-Object { [char]$_ })) + '.md'

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
    $importPromptName,
    $enhancementPlanName,
    'ai-spec.example.yaml',
    'adapters/README.md',
    'adapters/claude-code/CLAUDE.md.template',
    'adapters/claude-code/settings.json.template',
    'adapters/codex/AGENTS.md.template',
    'adapters/cursor/ai-spec.mdc.template',
    'adapters/github-copilot/copilot-instructions.md.template',
    'adapters/generic/START-PROMPT.md',
    'core/command-standard.md',
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
    'scripts/install.ps1',
    'scripts/validate.ps1'
)

foreach ($relativePath in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $root $relativePath) -PathType Leaf) "Missing file: $relativePath"
}

$rootMarkdown = @(Get-ChildItem -LiteralPath $root -File -Filter '*.md' | Select-Object -ExpandProperty Name)
$unexpectedRootMarkdown = @($rootMarkdown | Where-Object { $_ -notin @('AI-START.md', 'README.md', $importPromptName, $enhancementPlanName) })
Assert-True ($unexpectedRootMarkdown.Count -eq 0) "Unexpected root Markdown: $($unexpectedRootMarkdown -join ', ')"

$start = Read-ProjectFile 'AI-START.md'
foreach ($section in @('Startup Protocol', 'Project Stage Detection', 'AI Tool Detection', 'Security Baseline', 'Context Routing', 'Delivery Protocol')) {
    Assert-True ($start.Contains($section)) "AI-START.md missing section marker: $section"
}
Assert-True ($start.Contains('new-project')) 'AI-START.md does not route new projects'
Assert-True ($start.Contains('existing-project')) 'AI-START.md does not route existing projects'
Assert-True ($start.Contains('in-progress-project')) 'AI-START.md does not route in-progress projects'
Assert-True ($start.Contains('generic')) 'AI-START.md has no generic fallback'

foreach ($skill in @('product-architect', 'dev-implementation')) {
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
