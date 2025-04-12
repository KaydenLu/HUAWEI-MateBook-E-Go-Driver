@echo off
setlocal enabledelayedexpansion
set indexcode=0
set e_code=0
set exitcode=0

set index1=0
set index2=0
set index3=0
set index4=0
set ServiceName=HuaweiThpService
set count=0

cd %~dp0
Echo WScript.Echo((new Date()).getTime())>sjc.vbs
for /f %%a in ('cscript -nologo -e:jscript sjc.vbs') do set timestamp=%%a
del /f /q sjc.vbs

SET logFolder=C:\ProgramData\Huawei\MCU-OTA\SERVICE
IF NOT EXIST %logFolder% (
        MD %logFolder%
)

SET logFile=C:\ProgramData\Huawei\MCU-OTA\SERVICE\THP_service_unInstalllog_%timestamp%.txt
IF NOT EXIST %logFile% (
    type nul>%logFile%
)

echo %time% :Sc config HuaweiThpService start= disabled>>%logFile%
Sc config HuaweiThpService start= disabled>>%logFile%
if %ERRORLEVEL% neq 0 (
set /a e_code=%ERRORLEVEL%
set /a index1=2"<<"16
echo %time% :Sc config HuaweiThpService start= disabled error>>%logFile%
)

:step1
echo %time% :InstallUtil.exe /u HuaweiThpService.exe>>%logFile%
InstallUtil.exe /u HuaweiThpService.exe >>%logFile%
if %ERRORLEVEL% neq 0 (
set /a e_code=%ERRORLEVEL%
set /a index2=2"<<"17
echo %time% :InstallUtil.exe /u HuaweiThpService.exe error>>%logFile%
)

choice /t 5 /d y /n >nul >>%logFile%

set zt=""
echo  %time% zt: !zt!  >>%logFile%

echo %time% :check if exists %ServiceName% >>%logFile%
for /f "skip=3 tokens=1" %%i in ('sc query %ServiceName%') do set "zt=%%i" &goto :ExistOrNotByServiceName2

:ExistOrNotByServiceName2
echo  %time% zt: !zt!  >>%logFile%
echo %time% :entry ExistOrNotByServiceName2 >>%logFile%
if /i !count! equ 20 (
	echo  %time% :goto exit >>%logFile%
	set /a e_code=%ERRORLEVEL%
	set /a index3=2"<<"18
	goto exit
)

if /i "!zt!"=="STATE" (
    echo  %time% :%ServiceName% exists >>%logFile%
	set /a count+=1
	echo  %time% : count = !count! >>%logFile%
	goto step1
) else (
    echo  %time% :%ServiceName% not exists >>%logFile%
)

choice /t 5 /d y /n >nul

echo %time% :net stop "HuaweiThpService" >>%logFile%
net stop "HuaweiThpService" >>%logFile%
if %ERRORLEVEL% neq 0 (
	set /a e_code=%ERRORLEVEL%
	set /a index4=2"<<"19
	echo %time% :net stop "HuaweiThpService" error>>%logFile%
)

:exit
set /a indexcode=%index1% + %index2% + %index3% + %index4%
set /a exitcode=%indexcode%+%e_code%
exit /b %exitcode%