param([string]$Handle = "0x7E408B4", [string]$Keys = "{ENTER}", [int]$Wait = 5)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Fg {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
"@
Add-Type -AssemblyName System.Windows.Forms

$h = [IntPtr]([Convert]::ToInt64($Handle, 16))
[void][Win32Fg]::ShowWindow($h, 9)
[void][Win32Fg]::BringWindowToTop($h)
[void][Win32Fg]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 800
if ($Keys -ne "") {
    [System.Windows.Forms.SendKeys]::SendWait($Keys)
}
Start-Sleep -Seconds $Wait
$fg = [Win32Fg]::GetForegroundWindow()
Write-Output ("foreground=0x{0:X}" -f $fg.ToInt64())
