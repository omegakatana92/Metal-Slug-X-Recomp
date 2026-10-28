# Stage dist\windows\Metal Slug X-Windows-x64 and its zip.
#
# Usage: powershell -ExecutionPolicy Bypass -File scripts\package-windows.ps1
param(
    [string]$BuildDir = 'build-windows',
    [string]$VersionTag = ''
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$exe = Join-Path $root "$BuildDir\Release\Metal Slug X.exe"
if (-not (Test-Path $exe)) { throw "build the player first: $exe is missing" }

$out = Join-Path $root 'dist\windows\Metal Slug X-Windows-x64'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $out, (Join-Path $out 'LICENSES') | Out-Null

Copy-Item $exe $out
Copy-Item (Join-Path $root "$BuildDir\Release\SDL2.dll") $out

# MSVC runtime: the VS redistributable DLLs the exe actually imports.
# (The C++ runtime is not needed: the only C++ translation unit, ymfm, is
# linked into the executable without pulling in msvcp140.)
foreach ($dll in @('vcruntime140.dll', 'vcruntime140_1.dll')) {
    $found = Get-ChildItem 'C:\Program Files\Microsoft Visual Studio' -Recurse -Filter $dll -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -match '\\(x64|Hostx64\\x64)\\' } | Select-Object -First 1
    if ($found) { Copy-Item $found.FullName $out }
}

Copy-Item (Join-Path $root 'packaging\windows\README.txt') $out
Copy-Item (Join-Path $root 'packaging\windows\Play Metal Slug X.cmd') $out
Copy-Item (Join-Path $root 'packaging\windows\Prepare-ROMs.ps1') $out
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $out 'LICENSES\LICENSE.txt')
Copy-Item (Join-Path $root 'LICENSE-STATUS.md') (Join-Path $out 'LICENSES\LICENSE-STATUS.txt')
Copy-Item (Join-Path $root 'THIRD_PARTY_NOTICES.md') (Join-Path $out 'LICENSES\THIRD_PARTY_NOTICES.txt')
Copy-Item (Join-Path $root 'neogeorecomp\LICENSE') (Join-Path $out 'LICENSES\neogeorecomp.txt')
Copy-Item (Join-Path $root 'neogeorecomp\NOTICE') (Join-Path $out 'LICENSES\neogeorecomp-NOTICE.txt')
Copy-Item (Join-Path $root 'neogeorecomp\LICENSES\*.txt') (Join-Path $out 'LICENSES')

$hashes = Get-ChildItem $out -File | Sort-Object Name | ForEach-Object {
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$h  $($_.Name)"
}
Set-Content -Path (Join-Path $out 'SHA256SUMS.txt') -Value $hashes -Encoding ascii

$tag = if ($VersionTag) { "-$VersionTag" } else { '' }
$zip = Join-Path $root "dist\windows\Metal Slug X-Windows-x64$tag.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $out -DestinationPath $zip -CompressionLevel Optimal
Write-Host "wrote $zip" -ForegroundColor Green
