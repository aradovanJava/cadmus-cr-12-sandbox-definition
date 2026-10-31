# CADMUS-CR-12 - sandbox environment check for SC1 (VM1, Windows workstation)
#
#   powershell -ExecutionPolicy Bypass -File C:\Lab\verify-cr-env.ps1
#
# SC1 is the editor and browser; the application is built, run and analysed
# on V1 (Linux). This check covers SC1 and its connection to V1 and SQ1; run
# ~/lab-tools/verify-v1.sh on V1 for the build host. If anything reports
# MISSING or DOWN, tell your instructor before starting the lab.
#
# How a tool is judged: OK/MISSING is decided only by whether the command can
# be found (Get-Command). The version shown next to it is informational; a
# tool that prints its version oddly can never be reported as MISSING.

$ok = $true
$staleSession = $false

# The PATH this window inherited, and the PATH the machine actually has now.
$inheritedPath = $env:Path
$currentPath   = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                 [Environment]::GetEnvironmentVariable('Path', 'User')

function Find-Command([string]$cmd, [string]$path) {
    $saved = $env:Path
    try { $env:Path = $path; Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object -First 1 }
    finally { $env:Path = $saved }
}

function Check-Tool([string]$name, [string]$cmd, [string[]]$argList) {
    Write-Host -NoNewline ("{0,-18}" -f $name)
    $c = Find-Command $cmd $currentPath
    if (-not $c) {
        Write-Host "MISSING" -ForegroundColor Red
        $script:ok = $false
        return
    }
    $version = ''
    try {
        $lines = @(& $c.Source @argList 2>&1 | ForEach-Object { "$_" })
        $version = ($lines | Where-Object { $_.Trim() } | Select-Object -First 1)
    } catch { }
    if (Find-Command $cmd $inheritedPath) {
        Write-Host "OK    $version" -ForegroundColor Green
    } else {
        Write-Host "OK    $version   (not visible in this window yet - see below)" -ForegroundColor Yellow
        $script:staleSession = $true
    }
}

function Check-Url([string]$name, [string]$url, [switch]$Optional) {
    Write-Host -NoNewline ("{0,-18}" -f $name)
    try {
        $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $body = "$($r.Content)"
        if ($body.Length -gt 60) { $body = "HTTP $($r.StatusCode)" }
        Write-Host "OK    $body" -ForegroundColor Green
    } catch {
        if ($Optional) {
            Write-Host "DOWN  (optional) $url" -ForegroundColor Yellow
        } else {
            Write-Host "DOWN  $url" -ForegroundColor Red
            $script:ok = $false
        }
    }
}

Write-Host "`nCADMUS-CR-12 - sandbox environment check (SC1)`n" -ForegroundColor Cyan

Check-Tool "gcc (mingw-w64)" "gcc"   @('--version')
Check-Tool "g++"             "g++"   @('--version')
Check-Tool "make"            "make"  @('--version')
Check-Tool "cmake"           "cmake" @('--version')
Check-Tool "git"             "git"   @('--version')
Check-Tool "snyk"            "snyk"  @('--version')
Check-Tool "vs code"         "code"  @('--version')
Check-Tool "ssh"             "ssh"   @('-V')

foreach ($e in @(@('c/c++ extension', 'ms-vscode.cpptools-*'), @('remote-ssh ext.', 'ms-vscode-remote.remote-ssh-*'))) {
    Write-Host -NoNewline ("{0,-18}" -f $e[0])
    $ext = Get-ChildItem "$env:USERPROFILE\.vscode\extensions" -Directory -Filter $e[1] -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ext) { Write-Host "OK    $($ext.Name)" -ForegroundColor Green }
    else { Write-Host "not installed for this user - VS Code: Extensions" -ForegroundColor Yellow }
}

Write-Host -NoNewline ("{0,-18}" -f "ssh host v1")
if (Select-String -Path "$env:USERPROFILE\.ssh\config" -Pattern '^Host v1' -Quiet -ErrorAction SilentlyContinue) {
    Write-Host "OK    $env:USERPROFILE\.ssh\config" -ForegroundColor Green
} else { Write-Host "MISSING  (Remote-SSH can still use user@10.10.10.30)" -ForegroundColor Yellow }

Write-Host -NoNewline ("{0,-18}" -f "postman")
if (Test-Path "$env:LOCALAPPDATA\Postman\Postman.exe") { Write-Host "OK" -ForegroundColor Green }
else { Write-Host "not installed for this user (optional)" -ForegroundColor Yellow }

Write-Host ""
Write-Host -NoNewline ("{0,-18}" -f "v1 (ssh :22)")
$t = New-Object Net.Sockets.TcpClient
try {
    if ($t.ConnectAsync('10.10.10.30', 22).Wait(5000) -and $t.Connected) { Write-Host "OK    10.10.10.30" -ForegroundColor Green }
    else { Write-Host "DOWN  10.10.10.30:22" -ForegroundColor Red; $ok = $false }
} catch { Write-Host "DOWN  10.10.10.30:22" -ForegroundColor Red; $ok = $false } finally { $t.Close() }
Check-Url "sonarqube (SQ1)" "http://localhost:9000/api/system/status"
Check-Url "vulnshop"        "http://localhost:8080/shop" -Optional

Write-Host ""
if ($staleSession) {
    Write-Host "Some tools are installed but this window does not see them yet. Run" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File C:\Lab\fix-path.ps1" -ForegroundColor Yellow
    Write-Host "or sign out of Windows and back in.`n" -ForegroundColor Yellow
}
if ($ok) { Write-Host "SC1 ready. Now check V1:  ssh v1, then ~/lab-tools/verify-v1.sh" -ForegroundColor Green }
else     { Write-Host "Something is missing or down - raise it now." -ForegroundColor Red }
Write-Host "vulnshop is DOWN until you start it on V1 - that is expected.`n"
