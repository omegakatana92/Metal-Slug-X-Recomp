# Prepare the Metal Slug X ROM files from your own MAME zips.
#
# Usage (from this folder):
#   powershell -ExecutionPolicy Bypass -File .\Prepare-ROMs.ps1
#
# It asks for the MAME "mslugx" and "neogeo" zips and extracts them, flat,
# into the "roms" folder. It writes nothing outside this folder and never
# downloads ROMs.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out  = Join-Path $here 'roms'
$tmp  = Join-Path $here 'roms-tmp'

function AskPath($prompt, $defaultName) {
    $p = Read-Host "$prompt (full path to $defaultName)"
    $p = $p.Trim('"')
    if (-not (Test-Path $p)) { throw "not found: $p" }
    return $p
}

$gameZip = AskPath 'MAME mslugx.zip' 'mslugx.zip'
$biosZip = AskPath 'MAME neogeo.zip' 'neogeo.zip'

New-Item -ItemType Directory -Force -Path $out, $tmp | Out-Null
Expand-Archive -Path $gameZip -DestinationPath $tmp -Force
Expand-Archive -Path $biosZip -DestinationPath $tmp -Force

# The sets have no subdirectories in MAME, but zips repacked by other tools
# sometimes do; flatten so the runtime finds every file by name.
Get-ChildItem $tmp -Recurse -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $out $_.Name) -Force
}
Remove-Item $tmp -Recurse -Force

$needed = @('250-p1.p1','250-p2.ep1','250-c1.c1','250-c2.c2','250-c3.c3',
            '250-c4.c4','250-c5.c5','250-c6.c6','250-s1.s1','250-m1.m1',
            '250-v1.v1','250-v2.v2','250-v3.v3',
            'sp-s2.sp1','sfix.sfix','sm1.sm1','000-lo.lo')
$missing = $needed | Where-Object { -not (Test-Path (Join-Path $out $_)) }
if ($missing) {
    Write-Host 'Missing files in roms:' $($missing -join ', ') -ForegroundColor Red
    throw 'the ROM sets are incomplete or from a different revision'
}

Write-Host ''
Write-Host 'ROMs are ready in:' $out -ForegroundColor Green
Write-Host 'Run "Play Metal Slug X.cmd" to play.'
