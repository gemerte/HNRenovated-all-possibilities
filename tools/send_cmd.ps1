param(
    [string]$Game = "",
    [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Command
)

$ErrorActionPreference = "Stop"

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
    throw "Game folder not found. Pass it explicitly: .\send_cmd.ps1 -Game 'D:\Games\Project FeatherCage' fc status"
}

$path = Join-Path $game "HNRenovated\Binaries\Win64\ue4ss\Mods\FeatherCageCheats\commands.txt"
$line = ($Command -join " ").Trim()
if ($line -eq "") { throw "empty command" }

Add-Content -LiteralPath $path -Value $line -Encoding ASCII
Write-Output "queued: $line"
