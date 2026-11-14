param(
    [string]$GameDir = "C:\Users\Dmitriy\Desktop\Project FeatherCage",
    [string]$Iscc = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $Iscc) {
    $candidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe"),
        "C:\Program Files (x86)\Inno Setup 7\ISCC.exe",
        "C:\Program Files\Inno Setup 7\ISCC.exe"
    )
    $Iscc = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $Iscc) {
    throw "ISCC.exe (Inno Setup) not found. Install it: winget install JRSoftware.InnoSetup"
}
if (-not (Test-Path (Join-Path $GameDir "HNRenovated\Binaries\Win64\HNRenovated-Win64-Shipping.exe"))) {
    throw "Game folder not found: $GameDir"
}

$size = (Get-ChildItem $GameDir -Recurse -File | Measure-Object Length -Sum).Sum
Write-Host ("Game folder: {0} ({1:N2} GB)" -f $GameDir, ($size / 1GB))
Write-Host "Compiling full installer (this takes a while)..."

& $Iscc "/DGameDir=$GameDir" (Join-Path $root "FeatherCageCheats-Full.iss") | Write-Host
if ($LASTEXITCODE -ne 0) { throw "compilation failed (exit $LASTEXITCODE)" }

Get-ChildItem (Join-Path $root "dist") -Filter "*Full*.exe" |
    Select-Object FullName, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 2) } } | Format-Table -AutoSize
