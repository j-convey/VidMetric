# PowerShell script to deploy all required libraries for VidMetric

$BinDir = Join-Path "build" "bin"
$IsWin = $IsWindows -or ([Environment]::OSVersion.Platform -eq 'Win32NT')
$IsMac = $IsMacOS -eq $true

if ($IsWin) {
    $QtBinDir = "C:\msys64\mingw64\bin"
    $Ext = ".dll"
    Write-Host "Deploying Windows DLLs from $QtBinDir to $BinDir..." -ForegroundColor Green
} elseif ($IsMac) {
    if (Get-Command "brew" -ErrorAction SilentlyContinue) {
        $QtPath = brew --prefix qt@6
        $QtBinDir = Join-Path $QtPath "lib"
    } else {
        $QtBinDir = "/opt/homebrew/opt/qt@6/lib"
    }
    $Ext = ".dylib"
    Write-Host "Deploying macOS dylibs from $QtBinDir to $BinDir..." -ForegroundColor Green
} else {
    Write-Host "Deployment script currently tailored for Windows and macOS." -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path $BinDir)) {
    New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
}

# List of libraries to copy (using wildcards for cross-platform naming differences)
$LibsToCopy = @(
    # ICU libraries
    "*icuin*$Ext", "*icui18n*$Ext",
    "*icuuc*$Ext", 
    "*icudt*$Ext", "*icudata*$Ext",
    # Qt dependencies
    "*double-conversion*$Ext",
    "*b2*$Ext",
    "*pcre2-16*$Ext",
    "*zstd*$Ext",
    "*harfbuzz*$Ext",
    "*png16*$Ext",
    "*freetype*$Ext",
    "*bz2*$Ext",
    "*brotlidec*$Ext",
    "*brotlicommon*$Ext",
    "*graphite2*$Ext",
    "*md4c*$Ext",
    "*zlib*$Ext", "libz.*"
)

$CopiedCount = 0
$NotFoundCount = 0

foreach ($Pattern in $LibsToCopy) {
    $Files = Get-ChildItem -Path $QtBinDir -Filter $Pattern -ErrorAction SilentlyContinue
    
    if ($Files) {
        foreach ($File in $Files) {
            $DestPath = Join-Path $BinDir $File.Name
            if (-not (Test-Path $DestPath)) {
                Copy-Item $File.FullName -Destination $BinDir -Force
                Write-Host "  Copied: $($File.Name)" -ForegroundColor Cyan
                $CopiedCount++
            } else {
                Write-Host "  Already exists: $($File.Name)" -ForegroundColor Gray
            }
        }
    } else {
        $NotFoundCount++
    }
}

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "Copied: $CopiedCount libraries" -ForegroundColor Green

if ($IsWin) {
    Write-Host "`nYou can now run: .\$BinDir\VidMetric.exe" -ForegroundColor Cyan
} else {
    Write-Host "`nYou can now run: ./$BinDir/VidMetric" -ForegroundColor Cyan
}
