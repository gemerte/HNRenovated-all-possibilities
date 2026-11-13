param(
    [string]$Source = "C:\Users\Dmitriy\Downloads\F\FeatherCage\tools\screen.png",
    [int]$X = 0,
    [int]$Y = 0,
    [int]$W = 1920,
    [int]$H = 200,
    [string]$Out = "C:\Users\Dmitriy\Downloads\F\FeatherCage\tools\crop.png"
)
Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Image]::FromFile($Source)
$rect = New-Object System.Drawing.Rectangle $X, $Y, $W, $H
$bmp = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.DrawImage($src, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), $rect, [System.Drawing.GraphicsUnit]::Pixel)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $src.Dispose()
Write-Output $Out
