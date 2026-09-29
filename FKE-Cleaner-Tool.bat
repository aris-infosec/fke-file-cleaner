@echo off
setlocal EnableExtensions DisableDelayedExpansion

title FKE File Cleaner - Aris Patronis

:: ============================================================
::                    FKE FILE CLEANER
:: ============================================================
::
:: Scans ONLY the folder containing this BAT and all
:: subdirectories for *.fke files.
::
:: Every run performs a completely NEW scan.
:: Existing log files are ignored.
::
:: Created by Aris Patronis
:: ============================================================


:: ------------------------------------------------------------
:: SETTINGS
:: ------------------------------------------------------------

set "SCAN_DIR=%~dp0"
set "MAX_FILES=50000"

color 07


:: ------------------------------------------------------------
:: SAFETY - DO NOT SCAN DRIVE ROOT
:: ------------------------------------------------------------

if "%SCAN_DIR:~-3%"==":\" goto DRIVE_ROOT_ERROR


:: ------------------------------------------------------------
:: CREATE UNIQUE LOG FILE
:: ------------------------------------------------------------

for /f "delims=" %%A in ('powershell.exe -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd_HH-mm-ss-fff')" 2^>nul') do set "TIMESTAMP=%%A"

if not defined TIMESTAMP set "TIMESTAMP=unknown"

set "LOGFILE=%SCAN_DIR%FKE-Cleaner-%TIMESTAMP%-%RANDOM%.log"

:: Temporary files are created outside the scan folder.
set "TEMPPS=%TEMP%\FKE-Cleaner-%RANDOM%-%RANDOM%.ps1"
set "RESULTFILE=%TEMP%\FKE-Cleaner-Result-%RANDOM%-%RANDOM%.txt"


:: ------------------------------------------------------------
:: CREATE LOG
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
    echo.
    echo This is a NEW scan.
    echo Existing log files are ignored.
    echo ============================================================
    echo.
) > "%LOGFILE%"


:: ------------------------------------------------------------
:: MAIN HEADER
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
:: START SCAN QUESTION
:: ------------------------------------------------------------

echo ============================================================
echo                         READY
echo ============================================================
echo.
echo The program will perform a NEW scan of:
echo.
echo   %SCAN_DIR%
echo.
echo This folder and ALL subfolders will be searched for:
echo.
echo   *.fke
echo.
echo Existing log files will NOT affect this scan.
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

cls
color 07

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
echo This is a NEW scan.
echo.

>>"%LOGFILE%" echo Scan started: %DATE% %TIME%
>>"%LOGFILE%" echo.


:: ------------------------------------------------------------
:: PASS VARIABLES TO POWERSHELL
:: ------------------------------------------------------------

set "FKE_SCAN_ROOT=%SCAN_DIR%"
set "FKE_LOG=%LOGFILE%"
set "FKE_MAX=%MAX_FILES%"
set "FKE_RESULT=%RESULTFILE%"


:: ------------------------------------------------------------
:: CREATE POWERSHELL SCRIPT
:: ------------------------------------------------------------

> "%TEMPPS%" echo $ErrorActionPreference = 'Continue'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $root = $env:FKE_SCAN_ROOT
>>"%TEMPPS%" echo $log = $env:FKE_LOG
>>"%TEMPPS%" echo $maxFiles = [int]$env:FKE_MAX
>>"%TEMPPS%" echo $resultFile = $env:FKE_RESULT
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $scanErrors = @()
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host 'Scanning...' -ForegroundColor White
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # ALWAYS PERFORM A FRESH SCAN
>>"%TEMPPS%" echo # --------------------------------------------------------
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
>>"%TEMPPS%" echo     Write-Host ('[WARNING] Could not access: ' + $target) -ForegroundColor Yellow
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('[WARNING] Could not access: ' + $target)
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # SAFETY LIMIT
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($files.Count -gt $maxFiles^) {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'LIMIT'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host '                 SAFETY LIMIT EXCEEDED' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host ('Found: ' + $files.Count) -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ('Maximum allowed: ' + $maxFiles) -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'NO FILES WILL BE DELETED.' -ForegroundColor Red
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('SAFETY LIMIT EXCEEDED: ' + $files.Count)
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('Finished: ' + (Get-Date))
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     exit
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # NOTHING FOUND
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($files.Count -eq 0^) {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'NONE'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host '                     SCAN COMPLETE' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host '============================================================' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'NO .fke FILES WERE FOUND.' -ForegroundColor Green
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     if ($warnings -gt 0^) {
>>"%TEMPPS%" echo         Write-Host ('WARNING: ' + $warnings + ' location(s) could not be scanned.') -ForegroundColor Yellow
>>"%TEMPPS%" echo         Write-Host ''
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value 'No .fke files were found.'
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('Warnings: ' + $warnings)
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('Finished: ' + (Get-Date))
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     exit
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # FILES FOUND
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $totalBytes = ($files ^| Measure-Object -Property Length -Sum^).Sum
>>"%TEMPPS%" echo if ($null -eq $totalBytes^) { $totalBytes = 0 }
>>"%TEMPPS%" echo $totalMB = [math]::Round($totalBytes / 1MB, 2)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Set-Content -LiteralPath $resultFile -Value 'FOUND'
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
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # SIMPLE Y/N QUESTION
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================'
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo $answer = Read-Host ('Delete all ' + $files.Count + ' file(s)? [Y/N]')
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($answer -notmatch '^[Yy]$'^) {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'CANCELLED'
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo     Write-Host 'CANCELLED - No files were deleted.' -ForegroundColor Yellow
>>"%TEMPPS%" echo     Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value 'CANCELLED - No files were deleted.'
>>"%TEMPPS%" echo     Add-Content -LiteralPath $log -Value ('Finished: ' + (Get-Date))
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     exit
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # DELETE
>>"%TEMPPS%" echo # --------------------------------------------------------
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
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo foreach ($file in $files^) {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     if (-not (Test-Path -LiteralPath $file.FullName -PathType Leaf^)) {
>>"%TEMPPS%" echo         $gone++
>>"%TEMPPS%" echo         Write-Host ('[ALREADY GONE] ' + $file.FullName) -ForegroundColor Yellow
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[ALREADY GONE] ' + $file.FullName)
>>"%TEMPPS%" echo         continue
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     try {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo         Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo         $deleted++
>>"%TEMPPS%" echo         Write-Host ('[DELETED] ' + $file.FullName) -ForegroundColor Green
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[DELETED] ' + $file.FullName)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo     catch {
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo         $failed++
>>"%TEMPPS%" echo         Write-Host ('[FAILED] ' + $file.FullName) -ForegroundColor Red
>>"%TEMPPS%" echo         Write-Host ('         ' + $_.Exception.Message) -ForegroundColor Red
>>"%TEMPPS%" echo         Add-Content -LiteralPath $log -Value ('[FAILED] ' + $file.FullName + ' - ' + $_.Exception.Message)
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo     }
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo # FINAL RESULT
>>"%TEMPPS%" echo # --------------------------------------------------------
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($failed -eq 0^) {
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'SUCCESS'
>>"%TEMPPS%" echo } else {
>>"%TEMPPS%" echo     Set-Content -LiteralPath $resultFile -Value 'FAILED'
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo Write-Host '============================================================'
>>"%TEMPPS%" echo Write-Host '                      [3/3] COMPLETE'
>>"%TEMPPS%" echo Write-Host '============================================================'
>>"%TEMPPS%" echo Write-Host ''
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo if ($failed -eq 0^) {
>>"%TEMPPS%" echo     Write-Host 'ALL FILES HAVE BEEN DELETED.' -ForegroundColor Green
>>"%TEMPPS%" echo } else {
>>"%TEMPPS%" echo     Write-Host 'DELETION FINISHED WITH ERRORS.' -ForegroundColor Red
>>"%TEMPPS%" echo }
>>"%TEMPPS%" echo.
>>"%TEMPPS%" echo Write-Host ('Found:        ' + $files.Count)
>>"%TEMPPS%" echo Write-Host ('Deleted:      ' + $deleted) -ForegroundColor Green
>>"%TEMPPS%" echo Write-Host ('Already gone: ' + $gone)
>>"%TEMPPS%" echo Write-Host ('Failed:       ' + $failed)
>>"%TEMPPS%" echo Write-Host ('Warnings:     ' + $warnings)
>>"%TEMPPS%" echo.
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
>>"%TEMPPS%" echo exit


:: ------------------------------------------------------------
:: RUN POWERSHELL
:: ------------------------------------------------------------

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMPPS%"

set "PS_EXIT=%ERRORLEVEL%"


:: ------------------------------------------------------------
:: READ SIMPLE RESULT
:: ------------------------------------------------------------

set "SCAN_RESULT=UNKNOWN"

if exist "%RESULTFILE%" (
    set /p "SCAN_RESULT="<"%RESULTFILE%"
)


:: ------------------------------------------------------------
:: CLEAN TEMPORARY FILES
:: ------------------------------------------------------------

del /q "%TEMPPS%" >nul 2>&1
del /q "%RESULTFILE%" >nul 2>&1


:: ------------------------------------------------------------
:: ROUTE RESULT
:: ------------------------------------------------------------

if "%SCAN_RESULT%"=="NONE" goto FINAL_NONE
if "%SCAN_RESULT%"=="CANCELLED" goto FINAL_CANCELLED
if "%SCAN_RESULT%"=="LIMIT" goto FINAL_LIMIT
if "%SCAN_RESULT%"=="SUCCESS" goto FINAL_SUCCESS
if "%SCAN_RESULT%"=="FAILED" goto FINAL_FAILED

goto FINAL_ERROR


:: ============================================================
:: SUCCESS
:: ============================================================

:FINAL_SUCCESS

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
echo                    DELETION COMPLETE
echo.
echo.
echo              ALL .FKE FILES HAVE BEEN DELETED
echo.
echo ============================================================
echo.
echo The files that were deleted were:
echo.
echo ------------------------------------------------------------
echo.

findstr /C:"[DELETED]" "%LOGFILE%"

echo.
echo ------------------------------------------------------------
echo.
echo Summary:
echo.
echo The deletion operation completed successfully.
echo.
echo No deletion errors were reported.
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
:: DELETION FAILED
:: ============================================================

:FINAL_FAILED

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
echo                 DELETION FINISHED WITH ERRORS
echo.
echo.
echo Some .fke files could not be deleted.
echo.
echo ============================================================
echo.
echo Files successfully deleted:
echo.
findstr /C:"[DELETED]" "%LOGFILE%"
echo.
echo ------------------------------------------------------------
echo.
echo Files that failed:
echo.
findstr /C:"[FAILED]" "%LOGFILE%"
echo.
echo ============================================================
echo.
echo Please check the log for complete details.
echo.
echo Log file:
echo %LOGFILE%
echo.
echo ============================================================
echo.
echo Press any key to close this window...
pause >nul

exit /b 1


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
echo                 Nothing needed to be deleted.
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
:: DELETION CANCELLED
:: ============================================================

:FINAL_CANCELLED

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
echo                 No files were deleted.
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
echo Result returned:
echo %SCAN_RESULT%
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

exit /b 1


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
