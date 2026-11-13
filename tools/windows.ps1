Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class Win32Enum {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
$rows = New-Object System.Collections.Generic.List[object]
$cb = [Win32Enum+EnumWindowsProc]{
    param($h, $l)
    if ([Win32Enum]::IsWindowVisible($h)) {
        $sb = New-Object System.Text.StringBuilder 512
        [void][Win32Enum]::GetWindowText($h, $sb, 512)
        $t = $sb.ToString()
        if ($t.Trim().Length -gt 0) {
            $procId = 0
            [void][Win32Enum]::GetWindowThreadProcessId($h, [ref]$procId)
            $p = Get-Process -Id $procId -ErrorAction SilentlyContinue
            $rows.Add([pscustomobject]@{ Handle=("0x{0:X}" -f $h.ToInt64()); PID=$procId; Proc=$p.ProcessName; Title=$t })
        }
    }
    return $true
}
[void][Win32Enum]::EnumWindows($cb, [IntPtr]::Zero)
$rows | Where-Object { $_.Proc -like "*HNRenovated*" -or $_.Proc -like "*Feathercage*" -or $_.Title -like "*Neighbor*" -or $_.Title -like "*UE4SS*" } | Format-Table -AutoSize | Out-String -Width 200
