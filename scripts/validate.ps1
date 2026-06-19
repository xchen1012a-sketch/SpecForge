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
        'scripts\validate.ps1'
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $requiredPath))) {
            throw "Missing installed spec file: $requiredPath"
        }
    }

    $aiSpecPath = Join-Path $root 'ai-spec.yaml'
    $aiSpecContent = Get-Content -Raw -Encoding UTF8 -LiteralPath $aiSpecPath
    if (-not ($aiSpecContent -match '(?m)^  skillPolicy:\s*$')) {
        throw 'Missing ai.skillPolicy in ai-spec.yaml. Installed specs must persist skillPolicy.mode so AI tools do not silently bypass project skills.'
    }
    if (-not ($aiSpecContent -match '(?m)^    mode:\s*(project-first|local-first|hybrid)\b')) {
        throw 'Invalid or missing ai.skillPolicy.mode in ai-spec.yaml. Expected project-first, local-first, or hybrid.'
    }
    if (-not ($aiSpecContent -match '(?m)^    reportSkillSource:\s*true\b')) {
        throw 'Missing ai.skillPolicy.reportSkillSource: true in ai-spec.yaml. AI tools must report whether project/local skills were used.'
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
