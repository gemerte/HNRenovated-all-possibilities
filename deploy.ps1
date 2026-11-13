param(
    [string]$Game = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Find-GameRoot([string]$Explicit) {
    $candidates = @()
    if ($Explicit) { $candidates += $Explicit }
    $candidates += @(
        (Join-Path $env:USERPROFILE "Desktop\Project FeatherCage"),
        (Join-Path $env:USERPROFILE "Downloads\Project FeatherCage"),
        (Join-Path $env:USERPROFILE "Desktop\FeatherCage"),
        (Join-Path $env:USERPROFILE "Downloads\FeatherCage")
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path (Join-Path $c "HNRenovated\Binaries\Win64"))) { return $c }
    }
    return $null
}

$game = Find-GameRoot $Game
if (-not $game) {
    throw "Game folder not found. Pass it explicitly: .\deploy.ps1 -Game 'D:\Games\Project FeatherCage'"
}

$modsDir = Join-Path $game "HNRenovated\Binaries\Win64\ue4ss\Mods"
$dst = Join-Path $modsDir "FeatherCageCheats"

if (-not (Test-Path $modsDir)) {
    throw "UE4SS is not installed: no folder $modsDir (see README)"
}

if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
New-Item -ItemType Directory -Path $dst | Out-Null
Copy-Item (Join-Path $root "mod\FeatherCageCheats\*") $dst -Recurse -Force

# mods.txt: add the mod if it is not listed yet
$modsTxt = Join-Path $modsDir "mods.txt"
$content = if (Test-Path $modsTxt) { Get-Content $modsTxt } else { @() }
if (-not ($content -match '^\s*FeatherCageCheats\s*:')) {
    $content = @($content) + "FeatherCageCheats : 1"
    Set-Content -Path $modsTxt -Value $content
}

Write-Host "OK: $dst"
Get-ChildItem $dst -Recurse | Select-Object FullName, Length | Format-Table -AutoSize
