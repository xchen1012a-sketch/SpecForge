$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$installer = Join-Path $root 'scripts\install.ps1'
$tempRoot = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP ("ai-spec-v2-test-" + [guid]::NewGuid().ToString('N'))))

function Assert-Test {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $ownedClaude = Join-Path $tempRoot 'CLAUDE.md'
    [System.IO.File]::WriteAllText($ownedClaude, 'user-owned', [System.Text.UTF8Encoding]::new($false))

    & $installer -TargetRoot $tempRoot -Mode existing -Tools 'claude-code,codex,cursor,github-copilot' -Apply *> $null

    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.ai-spec\AI-START.md')) 'Installer did not copy AI-START.md'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.ai-spec\ai-spec.yaml')) 'Installer did not create ai-spec.yaml'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot 'AGENTS.md')) 'Installer did not create AGENTS.md'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.cursor\rules\ai-spec.mdc')) 'Installer did not create Cursor rules'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.github\copilot-instructions.md')) 'Installer did not create Copilot instructions'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.claude\settings.json')) 'Installer did not create Claude settings'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.agents\skills\product-architect\SKILL.md')) 'Installer did not create Codex skill'
    Assert-Test (Test-Path -LiteralPath (Join-Path $tempRoot '.claude\skills\dev-implementation\SKILL.md')) 'Installer did not create Claude skill'
    Assert-Test ((Get-Content -Raw -Encoding UTF8 -LiteralPath $ownedClaude) -eq 'user-owned') 'Installer overwrote an existing CLAUDE.md'

    $agents = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $tempRoot 'AGENTS.md')
    Assert-Test (-not $agents.Contains('{{')) 'Installer left placeholders in AGENTS.md'

    $profile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $tempRoot '.ai-spec\ai-spec.yaml')
    Assert-Test ($profile.Contains('stage: existing')) 'Installer did not write the selected project stage'

    & (Join-Path $tempRoot '.ai-spec\tests\template.tests.ps1') *> $null
    Write-Host 'Installer integration tests passed.' -ForegroundColor Green
}
finally {
    $resolvedTempBase = [System.IO.Path]::GetFullPath($env:TEMP)
    if ($tempRoot.StartsWith($resolvedTempBase) -and (Split-Path -Leaf $tempRoot).StartsWith('ai-spec-v2-test-')) {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}
