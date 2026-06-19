$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$testScript = Join-Path $root 'tests\template.tests.ps1'
$installTestScript = Join-Path $root 'tests\install.tests.ps1'
$skillTestScript = Join-Path $root 'tests\skills.tests.ps1'

$isTemplateRepository = (Test-Path -LiteralPath $testScript -PathType Leaf) -and
    (Test-Path -LiteralPath $installTestScript -PathType Leaf) -and
    (Test-Path -LiteralPath $skillTestScript -PathType Leaf)

if ($isTemplateRepository) {
    & $testScript
    & $installTestScript
    & $skillTestScript
}
else {
    foreach ($requiredPath in @(
        'AI-START.md',
        'README.md',
        'ai-spec.yaml',
        'business\quick-ref.md',
        'core\architecture.md',
        'core\delivery-standard.md',
        'core\security-standard.md',
        'core-lite\delivery-lite.md',
        'core-lite\security-lite.md',
        'core-lite\testing-lite.md',
        'scripts\audit-global-context.ps1',
        'scripts\maintain-context.ps1',
        'scripts\validate.ps1'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $requiredPath))) {
            throw "Missing installed spec file: $requiredPath"
        }
    }

    $aiSpecPath = Join-Path $root 'ai-spec.yaml'
    $aiSpecContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $aiSpecPath
    if (-not ($aiSpecContent -match '(?m)^  scope:\s*project-only\b')) {
        throw 'Missing spec.scope: project-only in ai-spec.yaml.'
    }
    if (-not ($aiSpecContent -match '(?m)^  skillPolicy:\s*$')) {
        throw 'Missing ai.skillPolicy in ai-spec.yaml. Installed specs must persist skillPolicy.mode so AI tools do not silently bypass project skills.'
    }
    if (-not ($aiSpecContent -match '(?m)^    mode:\s*(project-first|local-first|hybrid)\b')) {
        throw 'Invalid or missing ai.skillPolicy.mode in ai-spec.yaml. Expected project-first, local-first, or hybrid.'
    }
    if (-not ($aiSpecContent -match '(?m)^    reportSkillSource:\s*true\b')) {
        throw 'Missing ai.skillPolicy.reportSkillSource: true in ai-spec.yaml. AI tools must report whether project/local skills were used.'
    }
    if (-not ($aiSpecContent -match '(?m)^  outputLanguage:\s*$') -or -not ($aiSpecContent -match '(?m)^    default:\s*zh-CN\s*$')) {
        throw 'Missing ai.outputLanguage.default: zh-CN in ai-spec.yaml.'
    }
    if (-not ($aiSpecContent -match '(?m)^    locked:\s*true\b')) {
        throw 'Missing ai.outputLanguage.locked: true in ai-spec.yaml.'
    }
    if (-not ($aiSpecContent -match '(?m)^  maintenance:\s*$') -or -not ($aiSpecContent -match '(?m)^    strategy:\s*lazy\s*$')) {
        throw 'Missing context.maintenance.strategy: lazy in ai-spec.yaml.'
    }
    if (-not ($aiSpecContent -match '(?m)^    autoApply:\s*safe-only\s*$')) {
        throw 'Missing context.maintenance.autoApply: safe-only in ai-spec.yaml.'
    }
    if (-not ($aiSpecContent -match '(?m)^    singleReadMaxLines:\s*250\s*$')) {
        throw 'Missing context.maintenance.singleReadMaxLines: 250 in ai-spec.yaml.'
    }

    $quickRefPath = Join-Path $root 'business\quick-ref.md'
    $quickRefContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $quickRefPath
    $quickRefLines = @(Get-Content -Encoding UTF8 -LiteralPath $quickRefPath)
    if ($quickRefLines.Count -gt 40) {
        throw "Quick-ref exceeds 40 lines: $($quickRefLines.Count). Keep the daily entry lightweight."
    }
    if (-not $quickRefContent.Contains('outputLanguage: zh-CN')) {
        throw 'Quick-ref is missing outputLanguage: zh-CN.'
    }
    if ($quickRefContent -notmatch '(?m)^>\s*maintenanceDue:\s*(auto|\d{4}-\d{2}-\d{2})\s*$') {
        throw 'Quick-ref is missing a valid maintenanceDue marker.'
    }

    $quickRefStatusMatch = [regex]::Match($quickRefContent, '(?m)^>[^\r\n]*?[:\uFF1A]\s*(TEMPLATE_PLACEHOLDER|GENERATED)\b')
    $profileStatusMatch = [regex]::Match($aiSpecContent, '(?m)^\s{2}quickRefStatus:\s*(TEMPLATE_PLACEHOLDER|GENERATED)\s*(?:#.*)?$')
    if (-not $quickRefStatusMatch.Success -or -not $profileStatusMatch.Success -or $quickRefStatusMatch.Groups[1].Value -ne $profileStatusMatch.Groups[1].Value) {
        $quickValue = if ($quickRefStatusMatch.Success) { $quickRefStatusMatch.Groups[1].Value } else { '<missing>' }
        $profileValue = if ($profileStatusMatch.Success) { $profileStatusMatch.Groups[1].Value } else { '<missing>' }
        throw "Quick-ref status mismatch: quick-ref=$quickValue, ai-spec=$profileValue."
    }
    if ($quickRefStatusMatch.Success -and $quickRefStatusMatch.Groups[1].Value -eq 'GENERATED') {
        $pendingGenerate = -join (@(0x5F85, 0x751F, 0x6210) | ForEach-Object { [char]$_ })
        $pendingFill = -join (@(0x5F85, 0x586B, 0x5145) | ForEach-Object { [char]$_ })
        if ($quickRefContent.Contains($pendingGenerate) -or $quickRefContent.Contains($pendingFill) -or $quickRefContent -match '(?mi)^\s*-\s*TBD\b') {
            throw 'Generated quick-ref still contains placeholder content.'
        }

        $businessRulesPath = Join-Path $root 'business\business-rules.md'
        if (-not (Test-Path -LiteralPath $businessRulesPath -PathType Leaf)) {
            throw 'Generated business rules still contain placeholder content: file missing.'
        }
        $businessRulesContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $businessRulesPath
        if ($businessRulesContent.Contains($pendingGenerate) -or $businessRulesContent.Contains($pendingFill) -or $businessRulesContent -match '(?i)\bTBD\b') {
            throw 'Generated business rules still contain placeholder content.'
        }
        $sourceLabel = -join (@(0x6765, 0x6E90) | ForEach-Object { [char]$_ })
        $reliabilityLabel = -join (@(0x53EF, 0x9760, 0x5EA6) | ForEach-Object { [char]$_ })
        if ($businessRulesContent -notmatch ('\[' + [regex]::Escape($sourceLabel) + '[:\uFF1A]') -or
            $businessRulesContent -notmatch ('\[' + [regex]::Escape($reliabilityLabel) + '[:\uFF1A]')) {
            throw 'Generated business rules lack source/reliability evidence markers.'
        }

        $projectMapPath = Join-Path $root 'business\project-map.md'
        if (-not (Test-Path -LiteralPath $projectMapPath -PathType Leaf)) {
            throw 'Generated project map still contains placeholder content: file missing.'
        }
        $projectMapContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $projectMapPath
        if ($projectMapContent.Contains($pendingGenerate) -or $projectMapContent.Contains($pendingFill) -or $projectMapContent -match '(?i)\bTBD\b') {
            throw 'Generated project map still contains placeholder content.'
        }
    }
    if (-not $quickRefContent.Contains('workflows/project-planning.md') -or -not $quickRefContent.Contains('docs/plans/current.md')) {
        throw 'Quick-ref is missing the planning auto-trigger gate.'
    }

    $projectRoot = Split-Path -Parent $root
    foreach ($adapterRelativePath in @('CLAUDE.md', 'AGENTS.md', '.cursor\rules\ai-spec.mdc', '.github\copilot-instructions.md')) {
        $adapterPath = Join-Path $projectRoot $adapterRelativePath
        if (-not (Test-Path -LiteralPath $adapterPath -PathType Leaf)) { continue }
        $adapterContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $adapterPath
        if ($adapterContent.Contains('AI-START.md') -and -not $adapterContent.Contains('business/quick-ref.md')) {
            throw "Stale AI adapter forces full startup reads: $adapterRelativePath. Merge the dynamic quick-ref entry without overwriting project-owned instructions."
        }
    }

    $currentPlanPath = Join-Path $projectRoot 'docs\plans\current.md'
    if (Test-Path -LiteralPath $currentPlanPath -PathType Leaf) {
        $currentPlanLines = @(Get-Content -Encoding UTF8 -LiteralPath $currentPlanPath)
        if ($currentPlanLines.Count -gt 80) {
            throw "Current plan exceeds 80 lines: $($currentPlanLines.Count). Keep it as a lightweight phase pointer."
        }
    }

    $phaseRoot = Join-Path $projectRoot 'docs\plans\phases'
    if (Test-Path -LiteralPath $phaseRoot -PathType Container) {
        $completedStatusLabel = -join (@(0x5B8C, 0x6210, 0x72B6, 0x6001) | ForEach-Object { [char]$_ })
        $acceptanceEvidenceLabel = -join (@(0x9A8C, 0x6536, 0x8BC1, 0x636E) | ForEach-Object { [char]$_ })
        $completedPattern = '(?mi)^\s*-\s*\*\*(' + [regex]::Escape($completedStatusLabel) + '|status)\*\*\s*[:\uFF1A]\s*completed\s*$'
        $evidencePattern = '(?ms)^##\s+(' + [regex]::Escape($acceptanceEvidenceLabel) + '|Acceptance evidence)\s*\r?\n(?<body>.*?)(?=^##\s|\z)'
        foreach ($phaseFile in @(Get-ChildItem -LiteralPath $phaseRoot -File -Filter '*.md')) {
            $phaseContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $phaseFile.FullName
            if ($phaseContent -match $completedPattern) {
                $evidence = [regex]::Match($phaseContent, $evidencePattern)
                $concreteEvidence = @()
                if ($evidence.Success) {
                    $concreteEvidence = @($evidence.Groups['body'].Value -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object {
                        $_ -and $_ -notmatch '^[-*]\s*$' -and $_ -notmatch '[:\uFF1A]\s*$' -and $_ -notmatch '(?i)\b(TBD|TODO|placeholder)\b'
                    })
                }
                if (-not $evidence.Success -or $concreteEvidence.Count -eq 0) {
                    throw "Completed phase lacks acceptance evidence: $($phaseFile.FullName)"
                }
            }
        }
    }
    Write-Host 'Installed spec structure validation passed.' -ForegroundColor Green
}

$settingsPath = Join-Path $root 'adapters\claude-code\settings.json.template'
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    try {
        Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json | Out-Null
    }
    catch {
        Write-Host "Invalid JSON template: $settingsPath" -ForegroundColor Red
        throw
    }
}

$brokenLinks = [System.Collections.Generic.List[string]]::new()
$conflictMarkers = [System.Collections.Generic.List[string]]::new()
$markdownFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notmatch '[\\/]docs[\\/]legacy[\\/]' }

foreach ($file in $markdownFiles) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    $lines = Get-Content -Encoding UTF8 -LiteralPath $file.FullName
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Contains('[') -and $lines[$i].Contains('冲突')) {
            $relativeFile = $file.FullName.Substring($root.Length + 1)
            $lineNumber = $i + 1
            $conflictMarkers.Add("${relativeFile}:$lineNumber $($lines[$i].Trim())")
        }
    }

    $matches = [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')
    foreach ($match in $matches) {
        $target = $match.Groups[1].Value.Trim('<', '>')
        if ($target -match '^(https?://|#|mailto:)' -or $target.Contains('{{')) { continue }
        $targetWithoutAnchor = $target.Split('#')[0]
        if ([string]::IsNullOrWhiteSpace($targetWithoutAnchor)) { continue }
        $resolved = Join-Path $file.DirectoryName $targetWithoutAnchor
        if (-not (Test-Path -LiteralPath $resolved)) {
            $relativeFile = $file.FullName.Substring($root.Length + 1)
            $brokenLinks.Add("$relativeFile -> $target")
        }
    }
}

if ($conflictMarkers.Count -gt 0) {
    Write-Host 'Conflict summary:' -ForegroundColor Yellow
    foreach ($marker in $conflictMarkers) { Write-Host "- $marker" -ForegroundColor Yellow }
}

if ($brokenLinks.Count -gt 0) {
    Write-Host 'Broken local Markdown links:' -ForegroundColor Red
    foreach ($link in $brokenLinks) { Write-Host "- $link" -ForegroundColor Red }
    exit 1
}

Write-Host 'Structure, policy, skill, JSON, and Markdown link validation passed.' -ForegroundColor Green
