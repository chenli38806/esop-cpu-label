# esop-cpu-label one-line installer (multi-source, CN-friendly).
#
# Recommended on any Windows computer:
#   irm https://cdn.jsdelivr.net/gh/chenli38806/esop-cpu-label@main/install-online.ps1 | iex
#
# Mirrors are tried automatically in order:
#   1) cdn.jsdelivr.net   2) ghproxy.net   3) raw.githubusercontent.com
#
# Self-contained: checks Python, installs Pillow if missing, downloads
# esop-cpu-label.zip from the repo (falling back across mirrors), unpacks it
# into the Doubao user skill folder.
#
# NOTE: keep this file pure ASCII. Windows PowerShell 5.1 decodes downloaded
# UTF-8 text as ANSI and non-ASCII comment bytes can swallow following code.

$RepoOwner = "chenli38806"
$RepoName  = "esop-cpu-label"
$Branch    = "main"
$Target    = ""
$ZipName   = "esop-cpu-label.zip"

$ErrorActionPreference = "Stop"

if ($RepoOwner -eq "OWNER" -or [string]::IsNullOrWhiteSpace($RepoOwner)) {
    Write-Host "[ERR] RepoOwner is still the placeholder." -ForegroundColor Red
    exit 1
}

Write-Host "=== esop-cpu-label installer ==="
Write-Host "repo: $RepoOwner/$RepoName ($Branch)"

# ---- 1. python ----
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
    Write-Host "[ERR] python not found." -ForegroundColor Red
    Write-Host "      Install Python 3.9+ from https://www.python.org/downloads/"
    Write-Host "      and check 'Add python.exe to PATH'."
    exit 1
}
Write-Host "[OK] python: $python"

# ---- 2. pillow ----
& $python -c "import PIL" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[..] installing pillow ..."
    & $python -m pip install --quiet pillow
    & $python -c "import PIL" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERR] pillow install failed. Run manually: python -m pip install pillow" -ForegroundColor Red
        exit 1
    }
}
$pv = & $python -c "import PIL; print(PIL.__version__)"
Write-Host "[OK] pillow: $pv"

# ---- 3. download skill package (try mirrors in order) ----
$bases = @(
    "https://cdn.jsdelivr.net/gh/$RepoOwner/$RepoName@$Branch",
    "https://ghproxy.net/https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch",
    "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"
)

$tmp = Join-Path $env:TEMP ("esop_dl_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zip = Join-Path $tmp $ZipName

Add-Type -AssemblyName System.IO.Compression.FileSystem

$got = $false
foreach ($b in $bases) {
    $url = "$b/$ZipName"
    Write-Host "[..] downloading: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 60
        if (-not (Test-Path $zip)) { throw "no file written" }
        if ((Get-Item -LiteralPath $zip).Length -lt 100000) { throw "package too small (truncated?)" }
        $za = [System.IO.Compression.ZipFile]::OpenRead($zip)
        $names = $za.Entries | ForEach-Object { $_.FullName }
        $za.Dispose()
        if (-not ($names -match "SKILL\.md$")) { throw "SKILL.md missing inside zip" }
        $got = $true
        Write-Host "[OK] downloaded ($((Get-Item -LiteralPath $zip).Length) bytes, $($names.Count) entries)"
        break
    } catch {
        Write-Host "[WARN] source failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
    }
}

if (-not $got) {
    Write-Host "[ERR] all download sources failed." -ForegroundColor Red
    Write-Host "      Manual fallback: download $ZipName from the repo page,"
    Write-Host "      unzip it and copy the esop-cpu-label folder into:"
    Write-Host "      $env:LOCALAPPDATA\Doubao\User Data\Default\.doubao\agent_mode\workspace\.user_skills"
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

$ex = Join-Path $tmp "unpack"
New-Item -ItemType Directory -Force -Path $ex | Out-Null
Expand-Archive -LiteralPath $zip -DestinationPath $ex -Force

# find the folder that holds SKILL.md
$src = $null
if (Test-Path (Join-Path $ex "SKILL.md")) { $src = $ex }
if (-not $src) {
    $d = Get-ChildItem $ex -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | Select-Object -First 1
    if ($d) { $src = $d.FullName }
}
if (-not $src) {
    Write-Host "[ERR] SKILL.md not found after unpacking" -ForegroundColor Red
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# ---- 4. install ----
if (-not $Target) {
    $Target = Join-Path $env:LOCALAPPDATA "Doubao\User Data\Default\.doubao\agent_mode\workspace\.user_skills"
}
$dest = Join-Path $Target "esop-cpu-label"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $src "*") -Destination $dest -Recurse -Force
Remove-Item -LiteralPath (Join-Path $dest $ZipName) -Force -ErrorAction SilentlyContinue
Write-Host "[OK] skill installed to: $dest"

# ---- 5. sanity checks ----
$fonts = @("C:\Windows\Fonts\msyhbd.ttc", "C:\Windows\Fonts\msyh.ttc", "C:\Windows\Fonts\simhei.ttf")
$hit = $fonts | Where-Object { Test-Path $_ }
if ($hit) { Write-Host "[OK] chinese font: $(Split-Path $hit[0] -Leaf)" }
else { Write-Host "[WARN] no Microsoft YaHei; falls back to other CJK fonts" -ForegroundColor Yellow }

& $python -c "import ast,glob,os; [ast.parse(open(p,encoding='utf-8-sig').read()) for p in glob.glob(os.path.join(r'$dest','scripts','*.py'))]; print('[OK] scripts syntax check passed')"

foreach ($f in @("SKILL.md", "scripts\esop_build.py", "scripts\validate.py", "references\label-rules.md")) {
    if (-not (Test-Path (Join-Path $dest $f))) {
        Write-Host "[WARN] missing: $f" -ForegroundColor Yellow
    }
}

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. Restart the Doubao client, then say:" -ForegroundColor Cyan
Write-Host "  make an ESOP check image from this CPU label, lenovo PN xxx, supplier PN xxx"
