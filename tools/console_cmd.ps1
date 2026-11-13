param([string]$Handle = "0x7E408B4", [string]$Text = "fc help", [int]$Wait = 6)

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Con {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
}
"@
Add-Type -AssemblyName System.Windows.Forms

$h = [IntPtr]([Convert]::ToInt64($Handle, 16))
[void][Win32Con]::ShowWindow($h, 9)
[void][Win32Con]::BringWindowToTop($h)
[void][Win32Con]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 600

# открыть консоль клавишей ` (тильда/ё)
[System.Windows.Forms.SendKeys]::SendWait([string][char]96)
Start-Sleep -Milliseconds 900
[System.Windows.Forms.SendKeys]::SendWait($Text)
Start-Sleep -Milliseconds 300
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds $Wait
Write-Output "sent: $Text"
