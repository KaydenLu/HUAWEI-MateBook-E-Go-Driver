@echo off
setlocal enabledelayedexpansion
set indexcode=0
set e_code=0
set exitcode=0

set index1=0
set index2=0
set index3=0

cd %~dp0
Echo WScript.Echo((new Date()).getTime())>sjc.vbs
for /f %%a in ('cscript -nologo -e:jscript sjc.vbs') do set timestamp=%%a
del /f /q sjc.vbs

SET logFolder=C:\ProgramData\Huawei\MCU-OTA\SERVICE
IF NOT EXIST %logFolder% (
        MD %logFolder%
)

SET logFile=C:\ProgramData\Huawei\MCU-OTA\SERVICE\THP_service_Installlog_%timestamp%.txt
IF NOT EXIST %logFile% (
    type nul>%logFile%
)

echo %time% :InstallUtil.exe HuaweiThpService.exe>>%logFile%
InstallUtil.exe HuaweiThpService.exe >>%logFile%
if !ERRORLEVEL! neq 0 (
set /a e_code=!ERRORLEVEL!
set /a index1=1"<<"16
echo InstallUtil.exe HuaweiThpService.exe error>>%logFile%
)


sc failure HuaweiThpService reset=0 actions=restart/1000/restart/1000/restart/1000>>%logFile%
if !ERRORLEVEL! neq 0 (
set /a e_code=!ERRORLEVEL!
set /a index2"<<"17
echo %time%: sc failure HuaweiThpService reset=0 actions=restart/1000/restart/1000/restart/1000 error >>%logFile%
)

:exit
set /a indexcode=%index1% + %index2% + %index3%
set /a exitcode=%indexcode%+%e_code%
echo %time% exitcode:  %exitcode% >>%logFile%
exit /b %exitcode%