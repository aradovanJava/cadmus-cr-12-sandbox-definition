# CADMUS-CR-12 - make the lab tools available in this PowerShell window.
#
#   powershell -ExecutionPolicy Bypass -File C:\Lab\fix-path.ps1
#   (to fix the CURRENT window instead, dot-source it:  . C:\Lab\fix-path.ps1 )
#
# The tools are installed machine-wide, but a desktop session that was already
# open while the sandbox was being provisioned keeps an older PATH. This loads
# the machine + user PATH from the registry into the session and lists what
# resolves. Signing out and back in has the same effect for every window.

$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

Write-Host "`nTool check (this session):`n" -ForegroundColor Cyan
$allok = $true
foreach ($t in 'gcc', 'g++', 'make', 'cmake', 'git', 'snyk', 'code', 'ssh') {
    $c = Get-Command $t -ErrorAction SilentlyContinue
    if ($c) { Write-Host ("  {0,-20} OK    {1}" -f $t, $c.Source) -ForegroundColor Green }
    else    { Write-Host ("  {0,-20} MISSING" -f $t) -ForegroundColor Red; $allok = $false }
}
if ($allok) { Write-Host "`nAll tools resolve in this session." -ForegroundColor Green }
else        { Write-Host "`nSomething is still missing - send this output to the instructor." -ForegroundColor Yellow }
