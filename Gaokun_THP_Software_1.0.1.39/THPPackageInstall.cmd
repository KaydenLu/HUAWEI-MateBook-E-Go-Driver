@echo on
setlocal enabledelayedexpansion 
set indexcode=0
set e_code=0
set exitcode=0

set index1=0
set index2=0
set index3=0
set index4=0
set index5=0
set index6=0
set index7=0
set index8=0
set index9=0
set index10=0
set countNum=0

set bios_version=0
set ServiceName=HuaweiThpService

cd %~dp0
Echo WScript.Echo((new Date()).getTime())>sjc.vbs
for /f %%a in ('cscript -nologo -e:jscript sjc.vbs') do set timestamp=%%a
del /f /q sjc.vbs
SET logFolder=C:\ProgramData\Huawei\MCU-OTA\THPSoftwareInstall
IF NOT EXIST %logFolder% (
    MD %logFolder%
)

SET logFile=C:\ProgramData\Huawei\MCU-OTA\THPSoftwareInstall\THPSoftwareInstalllog_%timestamp%.txt
IF NOT EXIST %logFile% (
    type nul>%logFile%
)

:StateByServiceName1
sc failure HuaweiThpService reset=0 actions= "">>%logFile%
if !ERRORLEVEL! neq 0 (
::set /a e_code=%ERRORLEVEL%
::set /a index1=2"<<"10
echo %time%: sc failure HuaweiThpService reset=0 actions= "" error >>%logFile%
)

::Step 2, Stop HuaweiThpService service
echo %time% :stop HuaweiThpService >> %logFile%
net stop "HuaweiThpService" >> %logFile%
if !errorlevel! neq 0 (
    echo %time%: stop HuaweiThpService error >>%logFile%
)

::Waiting for the service to stop completely
choice /t 20 /d y /n >nul >>%logFile%

set zt=""
echo  %time% zt: !zt!  >>%logFile%

echo check %ServiceName% status
for /f "skip=3 tokens=4" %%i in ('sc query %ServiceName%') do set "zt=%%i" &goto :StateByServiceName2

:StateByServiceName2
echo  %time% zt: !zt!  >>%logFile%
if /i !countNum! equ 5 (
	echo  %time% :goto exit >>%logFile%
	set /a e_code=!ERRORLEVEL!
    set /a index2=2"<<"11
	goto exit
)

if /i "%zt%"=="RUNNING" (
    echo  %time% :%ServiceName% RUNNING >>%logFile%
	set /a countNum+=1
	echo  %time% : countNum = !countNum! >>%logFile%
	goto StateByServiceName1
) else (
    echo  %time% :%ServiceName% not RUNNING >>%logFile%
)

choice /t 10 /d y /n >nul 

echo ""| HxDisableTPINT_reg.x64.exe >>%logFile%
if !ERRORLEVEL! neq 0 (
	echo  %time% : start /wait HxDisableTPINT_reg.x64.exe error >>%logFile%
)

::Step 8, Update HIDMCUDriver
echo %time% :start install HIDMCUDriver>>%logFile%
start /wait HIDMCUDriver.exe
if !ERRORLEVEL! neq 0 (
    set /a e_code=!ERRORLEVEL!
    set /a index4=2"<<"13
    goto exit
)

::Step 9, Update SPIMCUDriver
echo %time% :start install SPIMCUDriver>>%logFile%
start /wait SPIMCUDriver.exe
if !ERRORLEVEL! neq 0 (
    set /a e_code=!ERRORLEVEL!
    set /a index5=2"<<"14
    goto exit
)

:: retrieve twice!
for /f  "delims=" %%j in ('wmic cpu get name') do (
	set b=%%j
	echo !b! | findstr "Gen">null&&(
		set running_ver_string=!b!
	)
)

::set running_ver_string="[FIRMWARE TYPE]  DIRAC_BRIDGE_BD 1.0.0.111"
echo %time% :running_ver_string = %running_ver_string% >>%logFile%

for /f "tokens=5" %%i in ("%running_ver_string%") do (
    ::echo %%i , %%j , %%k , %%l, %%m
    set run_version=%%i
)

echo %time% :run_version = %run_version% >>%logFile%

::for /f "delims=" %%t in ('wmic  bios get smbiosbiosversion ^| findstr 2.') do set bios_version=%%t
::echo bios_version = %bios_version% >>%logFile%

if %run_version%== 3 (
	::Step 7, Update HuaweiThpService service
	echo %time% :start update GaoKun_HuaweiThpService_GEN3>>%logFile%
	start /wait GaoKun_HuaweiThpService_GEN3.exe
	if !ERRORLEVEL! neq 0 (
		set /a e_code=!ERRORLEVEL!
		set /a index6=2"<<15
		echo  %time% : Update HuaweiThpService service error: !ERRORLEVEL! >>%logFile%
		goto exit
	)
) else (
	::Step 7, Update HuaweiThpService service
	echo %time% :start update GaoKun_HuaweiThpService_GEN2>>%logFile%
	start /wait GaoKun_HuaweiThpService_GEN2.exe
	if !ERRORLEVEL! neq 0 (
		set /a e_code=!ERRORLEVEL!
		set /a index7=2"<<"16
		echo  %time% : Update HuaweiThpService service error: !ERRORLEVEL! >>%logFile%
		goto exit
	)
)

:: step10, reg set config
::echo start reg set config>>%logFile%
::start /w mcu_ss_reg_set.exe>>%logFile%
::Step 11, Restart HuaweiThpService service
::echo %time% :start HuaweiThpService >> %logFile%
::net start "HuaweiThpService"
::if %errorlevel% neq 0 (
::    if %errorlevel% neq 2 (
::        set /a e_code = %errorlevel%
::        set /a index4=1"<<"23
::    )
::)

:exit
sc failure HuaweiThpService reset=0 actions=restart/1000/restart/1000/restart/1000>>%logFile%

echo %time% :install end>>%logFile%
set /a indexcode= %index1% + %index2% + %index3% + %index4% + %index5% + %index6% + %index7%
set /a exitcode=%indexcode% + %e_code%
echo %time% e_code:  %e_code% >>%logFile%
echo %time% exitcode:  %exitcode% >>%logFile%
exit /b %exitcode%