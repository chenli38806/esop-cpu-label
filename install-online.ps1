# esop-cpu-label one-line installer.
# Usage on any Windows computer:
#   irm https://raw.githubusercontent.com/<OWNER>/esop-cpu-label/main/install-online.ps1 | iex
#
# Self-contained: checks Python, installs Pillow if missing, downloads
# esop-cpu-label.zip from the repo, and copies the skill into the Doubao user
# skill folder.
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
Write-Host "repo: $RepoOwner/$RepoName"

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
    & $python -c "import PIL"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERR] pillow install failed. Run manually: python -m pip install pillow" -ForegroundColor Red
        exit 1
    }
}
$pv = & $python -c "import PIL; print(PIL.__version__)"
Write-Host "[OK] pillow: $pv"

# ---- 3. download skill package ----
$tmp = Join-Path $env:TEMP ("esop_dl_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
$zip = Join-Path $tmp $ZipName
$url = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/$ZipName"

Write-Host "[..] downloading skill package"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
} catch {
    Write-Host "[ERR] download failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "      raw.githubusercontent.com may be blocked here."
    Write-Host "      Fallback: open the repo page, download $ZipName, unzip, run install.ps1"
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}
if (-not (Test-Path $zip)) {
    Write-Host "[ERR] package not downloaded" -ForegroundColor Red
    exit 1
}

Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force

# find the folder that holds SKILL.md
$src = $null
if (Test-Path (Join-Path $tmp "SKILL.md")) { $src = $tmp }
if (-not $src) {
    $d = Get-ChildItem $tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | Select-Object -First 1
    if ($d) { $src = $d.FullName }
}
if (-not $src) {
    Write-Host "[ERR] SKILL.md not found in package" -ForegroundColor Red
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
Write-Host "[OK] skill installed to: $dest"

# ---- 5. font + syntax check ----
$fonts = @("C:\Windows\Fonts\msyhbd.ttc", "C:\Windows\Fonts\msyh.ttc", "C:\Windows\Fonts\simhei.ttf")
$hit = $fonts | Where-Object { Test-Path $_ }
if ($hit) { Write-Host "[OK] chinese font: $(Split-Path $hit[0] -Leaf)" }
else { Write-Host "[WARN] no Microsoft YaHei; falls back to Noto Sans CJK / PingFang" -ForegroundColor Yellow }

& $python -c "import ast,glob,os; [ast.parse(open(p,encoding='utf-8-sig').read()) for p in glob.glob(os.path.join(r'$dest','scripts','*.py'))]; print('[OK] scripts syntax check passed')"

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done. Restart the Doubao client, then say:" -ForegroundColor Cyan
Write-Host "  make an ESOP check image from this CPU label, lenovo PN xxx, supplier PN xxx"
