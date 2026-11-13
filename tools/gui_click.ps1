param(
    [string]$GuiHandle = "0x25140ACE",
    [string]$GameHandle = "0x16830A28",
    [int]$X = 532,
    [int]$Y = 71,
    [int]$Wait = 6,
    [switch]$NoMinimize
)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Fx {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, IntPtr pid);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

function Force-Foreground([IntPtr]$h) {
    $fg = [Fx]::GetForegroundWindow()
    $fgThread = [Fx]::GetWindowThreadProcessId($fg, [IntPtr]::Zero)
    $myThread = [Fx]::GetCurrentThreadId()
    [void][Fx]::AttachThreadInput($myThread, $fgThread, $true)
    [void][Fx]::BringWindowToTop($h)
    [void][Fx]::SetForegroundWindow($h)
    [void][Fx]::SetFocus($h)
    Start-Sleep -Milliseconds 400
    [void][Fx]::AttachThreadInput($myThread, $fgThread, $false)
}

$gui = [IntPtr]([Convert]::ToInt64($GuiHandle, 16))
$game = [IntPtr]([Convert]::ToInt64($GameHandle, 16))

if (-not $NoMinimize) {
    [void][Fx]::ShowWindow($game, 6)   # SW_MINIMIZE
    Start-Sleep -Milliseconds 800
}

[void][Fx]::ShowWindow($gui, 3)        # SW_MAXIMIZE
Start-Sleep -Milliseconds 500
Force-Foreground $gui

$fg = [Fx]::GetForegroundWindow()
Write-Output ("foreground=0x{0:X}" -f $fg.ToInt64())

$r = New-Object Fx+RECT
[void][Fx]::GetWindowRect($gui, [ref]$r)
Write-Output ("gui rect = {0},{1} - {2},{3}" -f $r.Left, $r.Top, $r.Right, $r.Bottom)

# click using absolute screen coords relative to the GUI window origin
$sx = $r.Left + $X
$sy = $r.Top + $Y
[void][Fx]::SetCursorPos($sx, $sy)
Start-Sleep -Milliseconds 300
[Fx]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 90
[Fx]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
Write-Output "clicked $sx,$sy"
Start-Sleep -Seconds $Wait

if (-not $NoMinimize) {
    [void][Fx]::ShowWindow($game, 9)   # SW_RESTORE
    Start-Sleep -Milliseconds 400
    Force-Foreground $game
}
Write-Output "done"
