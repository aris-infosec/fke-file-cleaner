@echo off
setlocal EnableExtensions DisableDelayedExpansion

title FKE File Cleaner - Aris Patronis

:: ============================================================
::                    FKE FILE CLEANER
:: ============================================================
:: Scans ONLY the folder containing this BAT and all
:: subdirectories for *.fke files.
::
:: Created by Aris Patronis
:: ============================================================

:: ------------------------------------------------------------
:: SETTINGS
:: ------------------------------------------------------------

set "SCAN_DIR=%~dp0"
set "MAX_FILES=50000"

:: White text on black background
color 07

:: ------------------------------------------------------------
:: Safety: do not allow scanning an entire drive
:: ------------------------------------------------------------

if "%SCAN_DIR:~-3%"==":\" goto DRIVE_ROOT_ERROR

:: ------------------------------------------------------------
:: Create timestamp
:: ------------------------------------------------------------

for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss')" 2^>nul') do set "TIMESTAMP=%%A"

if not defined TIMESTAMP set "TIMESTAMP=unknown"

set "LOGFILE=%SCAN_DIR%FKE-Cleaner-%TIMESTAMP%.log"
set "TEMPPS=%TEMP%\FKE-Cleaner-%RANDOM%-%RANDOM%.ps1"
set "RESULTFILE=%TEMP%\FKE-Cleaner-Result-%RANDOM%-%RANDOM%.txt"

:: ------------------------------------------------------------
:: Header
:: ------------------------------------------------------------

cls
color 07

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ------------------------------------------------------------
echo.
echo  SCAN LOCATION:
echo.
echo  %SCAN_DIR%
echo.
echo  SEARCH:
echo.
echo  *.fke
echo.
echo  SCOPE:
echo.
echo  THIS FOLDER AND ALL SUBDIRECTORIES ONLY
echo.
echo ------------------------------------------------------------
echo.

:: ------------------------------------------------------------
:: Create log
:: ------------------------------------------------------------

(
    echo ============================================================
    echo FKE FILE CLEANER LOG
    echo ============================================================
    echo Created by Aris Patronis
    echo Started: %DATE% %TIME%
    echo Scan location: %SCAN_DIR%
    echo Search: *.fke
    echo Maximum files: %MAX_FILES%
    echo ============================================================
    echo.
) > "%LOGFILE%"

:: ------------------------------------------------------------
:: Ask before scanning
:: ------------------------------------------------------------

echo ============================================================
echo                         READY
echo ============================================================
echo.
echo The program will scan:
echo.
echo   %SCAN_DIR%
echo.
echo This folder and ALL subfolders will be searched for:
echo.
echo   *.fke
echo.
echo NO FILES WILL BE DELETED DURING THE SCAN.
echo.
echo ============================================================
echo.

choice /C YN /N /M "Start scan? [Y/N]: "

if errorlevel 2 goto SCAN_CANCELLED
if errorlevel 1 goto START_SCAN

goto END


:: ============================================================
:: START SCAN
:: ============================================================

:START_SCAN

color 07
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo                    [1/3] SCANNING
echo ============================================================
echo.
echo Location:
echo %SCAN_DIR%
echo.
echo Searching for *.fke ...
echo.

>>"%LOGFILE%" echo Scan started: %DATE% %TIME%

:: ------------------------------------------------------------
:: Pass variables to PowerShell
:: ------------------------------------------------------------

set "FKE_SCAN_ROOT=%SCAN_DIR%"
set "FKE_LOG=%LOGFILE%"
set "FKE_MAX=%MAX_FILES%"
set "FKE_RESULT=%RESULTFILE%"

:: ------------------------------------------------------------
:: Create temporary PowerShell script
:: ------------------------------------------------------------

> "%TEMPPS%" echo $ErrorActionPreference = 'Continue'
>>"%TEMPPS%" echo $root = $env:FKE_SCAN_ROOT
>>"%TEMPPS%" echo $log = $env:FKE_LOG
>>"%TEMPPS%" echo $maxFiles = [int]$env:FKE_MAX
>>"%TEMPPS%" echo $resultFile = $env:FKE_RESULT
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $scanErrors = @()
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host '[*] Scanning...' -ForegroundColor White
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $files = @(Get-ChildItem -LiteralPath $root -Filter '*.fke' -File -Recurse -Force -ErrorAction SilentlyContinue -ErrorVariable scanErrors)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $warnings = @($scanErrors).Count
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo foreach ($err in $scanErrors^) {
>>"%TEMPPS%" echo     if ($err.TargetObject^) {
>>"%TEMPPS%" echo         $target = [string]$err.TargetObject
>>"%TEMPPS%" echo     } else {
>>"%TEMPPS%" echo         $target = [string]$err.Exception.Message
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Write-Host ('[WARNING] Could not access: ' + $target) -ForegroundColor Red
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('[WARNING] Could not access: ' + $target)
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($files.Count -gt $maxFiles^) {
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'LIMIT'
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host '                 SAFETY LIMIT EXCEEDED' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host ('Found: ' + $files.Count) -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ('Maximum allowed: ' + $maxFiles) -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'NO FILES WILL BE DELETED.' -ForegroundColor Red
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('SAFETY LIMIT EXCEEDED: ' + $files.Count)
>>"%TEMPPS%" echo     exit 2
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($files.Count -eq 0^) {
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'NONE'
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host '                     SCAN COMPLETE' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'NO .fke FILES WERE FOUND.' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     if ($warnings -gt 0^) {
>>"%TEMPPS%" echo         Write-Host ('WARNING: ' + $warnings + ' location(s) could not be scanned.') -ForegroundColor Red
>>"%TEMPPS%" echo         Write-Host ''
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value 'No .fke files were found.'
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('Warnings: ' + $warnings)
>>"%TEMPPS%" echo     exit 0
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Set-Content -LiteralPath $resultFile -Value 'FOUND'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $totalBytes = ($files ^| Measure-Object -Property Length -Sum^).Sum
>>"%TEMPPS%" echo if ($null -eq $totalBytes^) { $totalBytes = 0 }
>>"%TEMPPS%" echo $totalMB = [math]::Round($totalBytes / 1MB, 2)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '                     FILES FOUND' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host ('Found:      ' + $files.Count + ' file(s)') -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Total size: ' + $totalMB + ' MB') -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Warnings:   ' + $warnings) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host 'FILES FOUND:' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Found: ' + $files.Count + ' file(s)')
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Total size: ' + $totalMB + ' MB')
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Warnings: ' + $warnings)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ''
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value 'FILES FOUND:'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo foreach ($file in $files^) {
>>"%TEMPPS%" echo     Write-Host ('[FOUND] ' + $file.FullName) -ForegroundColor Red
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('[FOUND] ' + $file.FullName)
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($warnings -gt 0^) {
>>"%TEMPPS%" echo     Write-Host 'WARNING: Some locations could not be scanned.' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host 'Those locations are NOT included above.' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $answer = Read-Host ('Delete ALL ' + $files.Count + ' listed file(s)? Enter Y or N')
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($answer -notmatch '^[Yy]$'^) {
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'CANCELLED - No files were deleted.' -ForegroundColor Red
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value 'CANCELLED - No files deleted.'
>>"%TEMPPS%" echo     exit 0
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host 'WARNING: This operation permanently deletes the files.' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $confirmation = Read-Host ('Type DELETE ' + $files.Count + ' FILES to confirm')
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($confirmation -ne ('DELETE ' + $files.Count + ' FILES'^)) {
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'CANCELLED - Confirmation did not match.' -ForegroundColor Red
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value 'CANCELLED - Confirmation did not match.'
>>"%TEMPPS%" echo     exit 0
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '                      [2/3] DELETING' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $deleted = 0
>>"%TEMPPS%" echo $failed = 0
>>"%TEMPPS%" echo $gone = 0
>>"%TEMPPS%" echo $i = 0
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo foreach ($file in $files^) {
>>"%TEMPPS%" echo     $i++
>>"%TEMPPS%" echo     $percent = [math]::Round(($i / $files.Count^) * 100, 1^)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Write-Progress -Activity 'Deleting .fke files' -Status $file.FullName -PercentComplete $percent
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     if (-not (Test-Path -LiteralPath $file.FullName -PathType Leaf^)) {
>>"%TEMPPS%" echo         $gone++
>>"%TEMPPS%" echo         Write-Host ('[ALREADY GONE] ' + $file.FullName) -ForegroundColor Red
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[ALREADY GONE] ' + $file.FullName)
>>"%TEMPPS%" echo         continue
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     try {
>>"%TEMPPS%" echo         Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
>>"%TEMPPS%" echo         $deleted++
>>"%TEMPPS%" echo         Write-Host ('[DELETED] ' + $file.FullName) -ForegroundColor Red
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[DELETED] ' + $file.FullName)
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo     catch {
>>"%TEMPPS%" echo         $failed++
>>"%TEMPPS%" echo         Write-Host ('[FAILED] ' + $file.FullName) -ForegroundColor Red
>>"%TEMPPS%" echo         Write-Host ('         ' + $_.Exception.Message) -ForegroundColor Red
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[FAILED] ' + $file.FullName + ' - ' + $_.Exception.Message)
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Progress -Activity 'Deleting .fke files' -Completed
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '                      [3/3] COMPLETE' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host ('Found:        ' + $files.Count) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Deleted:      ' + $deleted) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Already gone: ' + $gone) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Failed:       ' + $failed) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ('Warnings:     ' + $warnings) -ForegroundColor Red
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host ('Log saved to: ' + $log) -ForegroundColor Red
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ''
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value 'SUMMARY'
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Found: ' + $files.Count)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Deleted: ' + $deleted)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Already gone: ' + $gone)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Failed: ' + $failed)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Warnings: ' + $warnings)
>>"%TEMPPS%" echo Add-Content -LiteralPath $log -Value ('Finished: ' + (Get-Date))
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo exit 0

:: ------------------------------------------------------------
:: Run PowerShell
:: ------------------------------------------------------------

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMPPS%"

set "PS_EXIT=%ERRORLEVEL%"

:: ------------------------------------------------------------
:: Determine result
:: ------------------------------------------------------------

set "SCAN_RESULT=UNKNOWN"

if exist "%RESULTFILE%" (
    set /p "SCAN_RESULT="<"%RESULTFILE%"
)

:: ------------------------------------------------------------
:: Delete temporary files
:: ------------------------------------------------------------

del /q "%TEMPPS%" >nul 2>&1
del /q "%RESULTFILE%" >nul 2>&1

:: ------------------------------------------------------------
:: Final screen
:: ------------------------------------------------------------

if /I "%SCAN_RESULT%"=="NONE" goto FINAL_NONE
if /I "%SCAN_RESULT%"=="FOUND" goto FINAL_FOUND
if /I "%SCAN_RESULT%"=="LIMIT" goto FINAL_LIMIT

goto FINAL_ERROR


:: ============================================================
:: NOTHING FOUND
:: ============================================================

:FINAL_NONE

color 0A
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo.
echo.
echo                 SCAN COMPLETED SUCCESSFULLY
echo.
echo.
echo                    NO FILES WERE FOUND
echo.
echo.
echo                 No .fke files were detected.
echo.
echo ============================================================
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 0


:: ============================================================
:: FILES FOUND
:: ============================================================

:FINAL_FOUND

color 0C
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo.
echo.
echo                    FILES WERE FOUND
echo.
echo.
echo              Review the results shown above.
echo.
echo              The scan detected one or more
echo                    .fke files.
echo.
echo ============================================================
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 0


:: ============================================================
:: SAFETY LIMIT
:: ============================================================

:FINAL_LIMIT

color 0C
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo.
echo.
echo                     SAFETY LIMIT HIT
echo.
echo.
echo More than %MAX_FILES% .fke files were detected.
echo.
echo NO FILES WERE DELETED.
echo.
echo ============================================================
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 2


:: ============================================================
:: ERROR
:: ============================================================

:FINAL_ERROR

color 0C
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo.
echo.
echo                       ERROR
echo.
echo.
echo The scanner did not return a normal result.
echo.
echo PowerShell exit code: %PS_EXIT%
echo.
echo ============================================================
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b %PS_EXIT%


:: ============================================================
:: SCAN CANCELLED
:: ============================================================

:SCAN_CANCELLED

color 07
cls

echo.
echo ============================================================
echo                    FKE FILE CLEANER
echo ============================================================
echo.
echo                    Created by Aris Patronis
echo.
echo ============================================================
echo.
echo.
echo                       CANCELLED
echo.
echo.
echo No scan was performed.
echo No files were deleted.
echo.
echo ============================================================
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 0


:: ============================================================
:: DRIVE ROOT ERROR
:: ============================================================

:DRIVE_ROOT_ERROR

color 0C
cls

echo.
echo ============================================================
echo                         ERROR
echo ============================================================
echo.
echo This BAT file is located directly in a drive root:
echo.
echo %SCAN_DIR%
echo.
echo For safety, scanning an entire drive is not permitted.
echo.
echo Put this BAT inside a normal folder and run it there.
echo.
echo Example:
echo.
echo C:\Tools\FKE-Cleaner.bat
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 1


:: ============================================================
:: END
:: ============================================================

:END

color 07
exit /b 0
