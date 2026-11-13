param(
    [switch]$NoStart,
    [int]$StartWait = 50,
    [int]$LevelWait = 40,
    [string]$KeyAfter = "{F11}"
)

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class W {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

function Get-GameHandle {
    $found = New-Object System.Collections.Generic.List[object]
    $cb = [W+EnumProc]{
        param($h, $l)
        if ([W]::IsWindowVisible($h)) {
            $sb = New-Object System.Text.StringBuilder 512
            [void][W]::GetWindowText($h, $sb, 512)
            if ($sb.ToString() -eq "HNRenovated") { $found.Add($h) }
        }
        return $true
    }
    [void][W]::EnumWindows($cb, [IntPtr]::Zero)
    if ($found.Count -gt 0) { return $found[0] }
    return [IntPtr]::Zero
}

function Focus-Game($h) {
    [void][W]::ShowWindow($h, 9)
    [void][W]::BringWindowToTop($h)
    [void][W]::SetForegroundWindow($h)
    Start-Sleep -Milliseconds 700
}

function Click-Rel($h, [int]$rx, [int]$ry) {
    $r = New-Object W+RECT
    [void][W]::GetWindowRect($h, [ref]$r)
    $x = $r.Left + $rx
    $y = $r.Top + $ry
    Focus-Game $h
    [void][W]::SetCursorPos($x, $y)
    Start-Sleep -Milliseconds 250
    [W]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 80
    [W]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
    Write-Output "click rel $rx,$ry -> screen $x,$y"
}

function Shot($path) {
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

$gameExe = "C:\Users\Dmitriy\Desktop\Project FeatherCage\Project Feathercage.exe"
$gameDir = "C:\Users\Dmitriy\Desktop\Project FeatherCage"
$shot = "C:\Users\Dmitriy\Downloads\F\FeatherCage\tools\screen.png"

if (-not $NoStart) {
    Get-Process HNRenovated-Win64-Shipping,"Project Feathercage" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 3
    Start-Process -FilePath $gameExe -WorkingDirectory $gameDir
    $deadline = (Get-Date).AddSeconds($StartWait)
    do {
        Start-Sleep -Seconds 2
        $h = Get-GameHandle
    } while ($h.ToInt64() -eq 0 -and (Get-Date) -lt $deadline)
} else {
    $h = Get-GameHandle
}

if ($h.ToInt64() -eq 0) { throw "game window not found" }
Write-Output ("handle=0x{0:X}" -f $h.ToInt64())

Focus-Game $h
Click-Rel $h 254 502     # New Game
Start-Sleep -Seconds 5
Click-Rel $h 689 489     # Play
Start-Sleep -Seconds $LevelWait

Focus-Game $h
[System.Windows.Forms.SendKeys]::SendWait($KeyAfter)
Start-Sleep -Seconds 6
Shot $shot
Write-Output "done"
