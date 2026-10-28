@echo off
rem Play Metal Slug X with the ROMs in the "roms" folder beside this file.
cd /d "%~dp0"
if not exist "roms\" (
  echo No "roms" folder found next to this file.
  echo Run Prepare-ROMs.ps1 first, or pass --rom-path DIR yourself.
  pause
  exit /b 1
)
start "" "Metal Slug X.exe" --rom-path "roms"
