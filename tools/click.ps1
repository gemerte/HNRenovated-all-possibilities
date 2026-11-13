param([string]$Handle = "0x7E408B4", [int]$X = 518, [int]$Y = 627, [int]$Wait = 10)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Click {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);
}
"@
$h = [IntPtr]([Convert]::ToInt64($Handle, 16))
[void][Win32Click]::ShowWindow($h, 9)
[void][Win32Click]::BringWindowToTop($h)
[void][Win32Click]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 700
[void][Win32Click]::SetCursorPos($X, $Y)
Start-Sleep -Milliseconds 250
[Win32Click]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Milliseconds 80
[Win32Click]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
Start-Sleep -Seconds $Wait
Write-Output "clicked $X,$Y"
