[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRoot,

    [ValidateSet('auto', 'new', 'existing', 'in-progress')]
    [string]$Mode = 'auto',

    [string[]]$Tools = @('generic'),

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$targetFullPath = [System.IO.Path]::GetFullPath($TargetRoot)
$validTools = @('generic', 'claude-code', 'codex', 'cursor', 'github-copilot')
$Tools = @($Tools | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
$invalidTools = @($Tools | Where-Object { $_ -notin $validTools })
if ($invalidTools.Count -gt 0) {
    throw "Unsupported tool adapter: $($invalidTools -join ', '). Use generic for unknown tools."
}

if (-not (Test-Path -LiteralPath $targetFullPath -PathType Container)) {
    throw "Target project directory does not exist: $targetFullPath"
}

if ($targetFullPath -eq [System.IO.Path]::GetFullPath($sourceRoot)) {
    throw 'Target project cannot be the template source directory.'
}

function Detect-Mode {
    param([string]$ProjectRoot)

    $gitDirectory = Join-Path $ProjectRoot '.git'
    if (Test-Path -LiteralPath $gitDirectory) {
        try {
            $status = & git -C $ProjectRoot status --short 2>$null
            if ($status) { return 'in-progress' }
        }
        catch { }
    }

    $signals = @(
        'package.json', 'pom.xml', 'build.gradle', 'build.gradle.kts',
        'pyproject.toml', 'requirements.txt', 'go.mod', 'Cargo.toml',
        'composer.json', 'mix.exs', 'src', 'app', 'backend', 'frontend'
    )
    foreach ($signal in $signals) {
        if (Test-Path -LiteralPath (Join-Path $ProjectRoot $signal)) {
            return 'existing'
        }
    }

    return 'new'
}

if ($Mode -eq 'auto') {
    $Mode = Detect-Mode -ProjectRoot $targetFullPath
}

$specTarget = Join-Path $targetFullPath '.ai-spec'
$actions = [System.Collections.Generic.List[string]]::new()
$conflicts = [System.Collections.Generic.List[string]]::new()

function Add-FileFromSource {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path -LiteralPath $Destination) {
        $script:conflicts.Add($Destination)
        return
    }

    $script:actions.Add("CREATE $Destination")
    if ($Apply) {
        $parent = Split-Path -Parent $Destination
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $Source -Destination $Destination
    }
}

function Add-RenderedFile {
    param(
        [string]$Source,
        [string]$Destination,
        [hashtable]$Variables
    )

    if (Test-Path -LiteralPath $Destination) {
        $script:conflicts.Add($Destination)
        return
    }

    $script:actions.Add("CREATE $Destination")
    if ($Apply) {
        $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $Source
        foreach ($key in $Variables.Keys) {
            $content = $content.Replace("{{$key}}", [string]$Variables[$key])
        }
        $parent = Split-Path -Parent $Destination
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        [System.IO.File]::WriteAllText($Destination, $content, [System.Text.UTF8Encoding]::new($false))
    }
}

$runtimeFiles = @(
    'AI-START.md',
    'README.md',
    'ai-spec.example.yaml'
)

foreach ($relativePath in $runtimeFiles) {
    Add-FileFromSource -Source (Join-Path $sourceRoot $relativePath) -Destination (Join-Path $specTarget $relativePath)
}

$runtimeDirectories = @(
    'adapters', 'business', 'contracts', 'core', 'governance',
    'profiles', 'scripts', 'skills', 'stacks', 'tests', 'workflows'
)

foreach ($directory in $runtimeDirectories) {
    $sourceDirectory = Join-Path $sourceRoot $directory
    Get-ChildItem -LiteralPath $sourceDirectory -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($sourceRoot.Length + 1)
        Add-FileFromSource -Source $_.FullName -Destination (Join-Path $specTarget $relativePath)
    }
}

$guide = Join-Path $sourceRoot 'docs\使用指南.md'
if (Test-Path -LiteralPath $guide) {
    Add-FileFromSource -Source $guide -Destination (Join-Path $specTarget 'docs\使用指南.md')
}

$profileDestination = Join-Path $specTarget 'ai-spec.yaml'
if (-not (Test-Path -LiteralPath $profileDestination)) {
    $actions.Add("CREATE $profileDestination")
    if ($Apply) {
        $profile = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $sourceRoot 'ai-spec.example.yaml')
        $profile = $profile -replace 'stage: new # new \| existing \| in-progress', "stage: $Mode # new | existing | in-progress"
        $projectName = Split-Path -Leaf $targetFullPath
        $profile = $profile.Replace('name: example-project', "name: $projectName")
        [System.IO.File]::WriteAllText($profileDestination, $profile, [System.Text.UTF8Encoding]::new($false))
    }
}
else {
    $conflicts.Add($profileDestination)
}

$variables = @{
    'PROJECT_NAME' = (Split-Path -Leaf $targetFullPath)
    'AI_SPEC_PATH' = '.ai-spec'
}

foreach ($tool in ($Tools | Select-Object -Unique)) {
    switch ($tool) {
        'claude-code' {
            Add-RenderedFile -Source (Join-Path $sourceRoot 'adapters\claude-code\CLAUDE.md.template') -Destination (Join-Path $targetFullPath 'CLAUDE.md') -Variables $variables
            Add-FileFromSource -Source (Join-Path $sourceRoot 'adapters\claude-code\settings.json.template') -Destination (Join-Path $targetFullPath '.claude\settings.json')
            foreach ($skill in @('product-architect', 'dev-implementation')) {
                $sourceSkill = Join-Path $sourceRoot "skills\$skill"
                Get-ChildItem -LiteralPath $sourceSkill -Recurse -File | ForEach-Object {
                    $skillRelative = $_.FullName.Substring($sourceSkill.Length + 1)
                    Add-FileFromSource -Source $_.FullName -Destination (Join-Path $targetFullPath ".claude\skills\$skill\$skillRelative")
                }
            }
        }
        'codex' {
            Add-RenderedFile -Source (Join-Path $sourceRoot 'adapters\codex\AGENTS.md.template') -Destination (Join-Path $targetFullPath 'AGENTS.md') -Variables $variables
            foreach ($skill in @('product-architect', 'dev-implementation')) {
                $sourceSkill = Join-Path $sourceRoot "skills\$skill"
                Get-ChildItem -LiteralPath $sourceSkill -Recurse -File | ForEach-Object {
                    $skillRelative = $_.FullName.Substring($sourceSkill.Length + 1)
                    Add-FileFromSource -Source $_.FullName -Destination (Join-Path $targetFullPath ".agents\skills\$skill\$skillRelative")
                }
            }
        }
        'cursor' {
            Add-RenderedFile -Source (Join-Path $sourceRoot 'adapters\cursor\ai-spec.mdc.template') -Destination (Join-Path $targetFullPath '.cursor\rules\ai-spec.mdc') -Variables $variables
        }
        'github-copilot' {
            Add-RenderedFile -Source (Join-Path $sourceRoot 'adapters\github-copilot\copilot-instructions.md.template') -Destination (Join-Path $targetFullPath '.github\copilot-instructions.md') -Variables $variables
        }
        'generic' { }
    }
}

Write-Host "AI Spec installation plan" -ForegroundColor Cyan
Write-Host "Target: $targetFullPath"
Write-Host "Detected mode: $Mode"
Write-Host "Tools: $($Tools -join ', ')"
Write-Host "Apply: $([bool]$Apply)"
Write-Host "Creates: $($actions.Count)"
foreach ($action in $actions) { Write-Host "- $action" }

if ($conflicts.Count -gt 0) {
    Write-Host "Existing files kept unchanged: $($conflicts.Count)" -ForegroundColor Yellow
    foreach ($conflict in $conflicts) { Write-Host "- KEEP $conflict" }
    Write-Host 'Review and merge these files semantically; the installer never overwrites them.' -ForegroundColor Yellow
}

if (-not $Apply) {
    Write-Host 'Dry-run only. Re-run with -Apply to create missing files.' -ForegroundColor Yellow
}
else {
    Write-Host 'Installation completed without overwriting existing files.' -ForegroundColor Green
}
