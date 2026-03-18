[CmdletBinding()]
param(
    [string]$IdeDir,
    [string]$Product = 'IntelliJIdea',
    [string]$Version = '2025.3',
    [string]$BaseDir = "$env:LOCALAPPDATA\JetBrains",
    [switch]$AutoDetectLatest,
    [switch]$SkipProcessCheck
)

$ErrorActionPreference = 'Stop'

function Resolve-IdeDir {
    param(
        [string]$ExplicitIdeDir,
        [string]$Product,
        [string]$Version,
        [string]$BaseDir,
        [switch]$AutoDetectLatest
    )

    if ($ExplicitIdeDir) {
        return $ExplicitIdeDir
    }

    if (-not (Test-Path $BaseDir)) {
        throw "JetBrains base directory not found: $BaseDir"
    }

    if ($AutoDetectLatest) {
        $match = Get-ChildItem $BaseDir -Directory |
            Where-Object { $_.Name -like "$Product*" } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if (-not $match) {
            throw "No JetBrains profile found for product prefix '$Product' under $BaseDir"
        }

        return $match.FullName
    }

    return (Join-Path $BaseDir ($Product + $Version))
}

$resolvedIdeDir = Resolve-IdeDir -ExplicitIdeDir $IdeDir -Product $Product -Version $Version -BaseDir $BaseDir -AutoDetectLatest:$AutoDetectLatest

if (-not (Test-Path $resolvedIdeDir)) {
    throw "IDE profile directory not found: $resolvedIdeDir"
}

if (-not $SkipProcessCheck) {
    $running = Get-Process idea64 -ErrorAction SilentlyContinue
    if ($running) {
        $pids = ($running | Select-Object -ExpandProperty Id) -join ', '
        throw "idea64.exe is still running (PID: $pids). Close IntelliJ IDEA completely before cleaning caches."
    }
}

$targets = @(
    'caches',
    'index',
    'tmp',
    'httpFileSystem',
    'jcef_cache',
    'compile-server',
    'compiler',
    'vcs-log',
    'Maven',
    'icon-cache-v1.db',
    '.pid',
    '.port'
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $resolvedIdeDir ("cache_cleanup_backup_" + $timestamp)
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$moved = New-Object System.Collections.Generic.List[string]
$missing = New-Object System.Collections.Generic.List[string]

foreach ($name in $targets) {
    $src = Join-Path $resolvedIdeDir $name
    if (Test-Path $src) {
        Move-Item -Path $src -Destination (Join-Path $backupDir $name) -Force
        $moved.Add($name) | Out-Null
    }
    else {
        $missing.Add($name) | Out-Null
    }
}

[pscustomobject]@{
    IdeDir    = $resolvedIdeDir
    BackupDir = $backupDir
    Moved     = ($moved -join ', ')
    Missing   = ($missing -join ', ')
}
