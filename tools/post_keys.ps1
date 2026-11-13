param(
    [string]$Handle = "0x16830A28",
    [string]$Text = "fc status",
    [switch]$OpenConsole
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PK {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
}
"@

$h = [IntPtr]([Convert]::ToInt64($Handle, 16))
[void][PK]::ShowWindow($h, 9)
[void][PK]::BringWindowToTop($h)
[void][PK]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 500

function KeyDown([int]$vk) {
    $sc = [PK]::MapVirtualKey([uint32]$vk, 0)
    $lp = [IntPtr]([int64](1 -bor ($sc -shl 16)))
    [void][PK]::PostMessage($h, 0x0100, [IntPtr]$vk, $lp)
}
function KeyUp([int]$vk) {
    $sc = [PK]::MapVirtualKey([uint32]$vk, 0)
    $lp = [IntPtr]([int64](1 -bor ($sc -shl 16) -bor 0xC0000000))
    [void][PK]::PostMessage($h, 0x0101, [IntPtr]$vk, $lp)
}
function SendChar([char]$c) {
    [void][PK]::PostMessage($h, 0x0102, [IntPtr][int]$c, [IntPtr]1)
}

if ($OpenConsole) {
    KeyDown 0xC0
    KeyUp 0xC0
    Start-Sleep -Milliseconds 700
}

foreach ($c in $Text.ToCharArray()) {
    SendChar $c
    Start-Sleep -Milliseconds 15
}
Start-Sleep -Milliseconds 150
KeyDown 0x0D
SendChar ([char]13)
KeyUp 0x0D
Write-Output "posted: $Text"
