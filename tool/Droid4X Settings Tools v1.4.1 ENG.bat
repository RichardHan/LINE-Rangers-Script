@echo off && setlocal ENABLEDELAYEDEXPANSION
color 0a && set title=Droid4X Setting Tools v1.4.1
CHCP>nul 2>nul||set path=%systemroot%\system32;%path%
title %title%
:BatchGotAdmin
:-------------------------------------
cls
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del /q /f "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------
:begin
echo.
echo.Finding Oracle VirtualBox path...
echo.
if exist "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" (
	set VboxPath=%ProgramFiles%\Oracle\VirtualBox\
) else (
    for /f "tokens=2,*" %%i in ('"reg query "HKLM\SOFTWARE\Oracle\VirtualBox" /v InstallDir 2>nul|findstr /i "InstallDir" 2>nul"') do (
		if exist "%%~jVBoxManage.exe" (
        	set VboxPath=%%~j
		)
    )
)

echo. Finding Droid4X installation path...
echo %PROCESSOR_ARCHITECTURE%|findstr /i "64">nul && (
	set D4Reg="HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Droid4X"
) || (
	set D4Reg="HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Droid4X"
)
for /f "tokens=2,*" %%i in ('"reg query %D4Reg% /v DisplayIcon 2>nul|findstr /i "Droid4X" 2>nul"') do (
	rem get D4 path
	set D4Path=%%~dpj
)
echo.
if not defined D4Path (
	echo. Cannot find Droid4X, please run it first time before use.
	set /p lgnore="If you make sure you have installed Droid4X correctly￡?pls input [Y] to skip this detection￡o"
	if /i "!lgnore!"=="Y" goto :checkVbox
	PAUSE
	exit
)
:checkVbox
if not defined VboxPath (
	echo. Unable to find Oracle VirtualBox, this tool will not work.
	echo.
	echo. This program will install Oracle VM VirtualBox
	echo.
	pause
	call :ReInstallVBOX
)

cd /d "%VboxPath%"
call :Format
call :Info

VBoxManage showvminfo %ova% --machinereadable|findstr /i "VMState"|findstr running>nul 2>nul && (
	echo.
	for /l %%i in (1 1 3) do (
		cls
		echo.
		echo. ★★★★★★★★★★★★★★★★★★★★★★
		echo. ★                                        ★
	echo. ★          Droid4X is running            ★
	echo. ★        You cannot modify anything      ★
	echo. ★       adb will start after 5 seconds   ★
	echo. ★                                        ★
	echo. ★★★★★★★★★★★★★★★★★★★★★★
	)
	ping 127.0.0.1 -n 5 >nul 2>nul
)

:menu
cls & title %title%
:menuNocls
echo.
rem Initialize variable
set memory=
set DPI=
set pixels=
set updata=
set menu=
set Q=
set checks=
set adb="%D4Path%\adb.exe" -s 127.0.0.1:%adbPort%
VBoxManage showvminfo %ova% --machinereadable|findstr /i "VMState"|findstr running>nul 2>nul && (
	echo.
	echo. Droid4X simulator is running, you can not make any changes.You can only view %ova% status and infomation
	echo.
	echo -----===== Please select an action to perform =====-----
	echo. 1. Modify adb connection port
	echo. 2. Connect Droid4X to ADB
	echo. 3. Connect Droid4X to ADB with ADB Shell command
	echo. 4. Remount SD card
	echo. 5. modify adb connection name
	echo. 
	echo. 9. See information about the connected Android devices
	echo. 10. View Droid4X setting information
	echo. 11. View Droid4X multi player
	echo. 
	echo. D1. Enter VirtualBox directory
	echo. D2. Enter Droid4X directory
	echo. Q1. Repair network issue(including:blank map\stuck at 80 percent)
	echo. Q2. Fix no Root grant
	echo. 
	echo. *. Droid4X startup exception check
	echo. 0. update address
	echo.
	echo. If you want to modify the settings, turn off the emulator and then run the program
echo -----==================================-----
set /p checks="Please enter the number you want to perform the operation:"
	if "!checks!"=="0" goto :log
	if "!checks!"=="1" (
		echo Current %ova% adb port: 127.0.0.1:%adbPort%
		set /p port="If you want reconnect, pls input adb port above"
	)
	if "!checks!"=="2" call :ConnectDroid4x
	if "!checks!"=="3" call :ConnectDroid4x && %adb% shell
	if "!checks!"=="4" call :RemountSD
	if "!checks!"=="9" goto :Devices
	if "!checks!"=="10" goto :Report
	if "!checks!"=="11" call :listVMS
	if /i "!checks!"=="*" goto :checkPort
	if /i "!checks!"=="-" goto :setting
	if /i "!checks!"=="D1" cd /d "%VboxPath%" && cmd
	if /i "!checks!"=="D2" cd /d "%D4Path%" && cmd
	if /i "!checks!"=="Q1" call :resetMap
	if /i "!checks!"=="Q2" call :FixedRoot
	cls
	goto :menu
)

:Setting
cls
echo.
if defined VboxPath (
	echo Your Oracle VirtualBox path: %VboxPath%
) else (
	echo Unable to find Oracle VirtualBox
)
echo.
echo -----===== Please select an action to perform =====-----
echo. 1. Modify the resolution and DPI
echo. 2. Modify the resolution
echo. 3. Modify DPI
echo. 4. Modifying RAM
echo. 5. Modify CPU cores
echo. --------------------------------------
echo. 6. On\off the virtual softkeys
echo. 7. Open VirtualBox Manager
echo. 
echo. 10. View Droid4X setting information
echo. 11. Switch Droid4X multi player
echo. 
echo. D1. Enter VirtualBox directory
echo. D2. Enter Droid4X directory
echo. 0. update address
echo. ----------========== fixed problem ==========----------
echo. Q1. fix gps map blank or exception
echo.
echo. If occur any error in running this tools, or cannot modify ,pls run as administrator
echo. Written by MarsCat(QQ:391616001)		Droid4X QQ group:369149979 &echo. Translated by max20091 (Email: boostyourprogram@gmail.com) (Youtube: max20091)&echo. Translated by 店小六(QQ: 823070287)
echo -----==============================-----
set /p menu="Please enter the number you want to perform the operation:"
if "%menu%"=="1" goto :Graph
if "%menu%"=="2" (set DPI=%DefaultDPI%) && goto :Graph
if "%menu%"=="3" (set pixels=%DefaultGraph%) && goto :DPI
if "%menu%"=="4" goto :Memory
if "%menu%"=="5" goto :CPU
if "%menu%"=="6" goto :navBar
if "%menu%"=="7" start "" "%VboxPath%VirtualBox.exe"
if "%menu%"=="9" goto :ReInstallVBOX
if "%menu%"=="10" goto :Report
if "%menu%"=="11" call :listVMS
if "%menu%"=="*" goto :checkPort
if "%menu%"=="0" goto :log
if /I "%menu%"=="D1" cd /d "%VboxPath%" && cmd
if /I "%menu%"=="D2" cd /d "%D4Path%" && cmd
if /i "%menu%"=="Q1" call :resetMap
cls
goto :menu

:Graph
cls
echo.
echo ------------- Horizontal screen resolution presets -------------
echo.  1.  480 x  320 DPI 120(Landscape)
echo.  2.  640 x  360 DPI 160(Landscape)
echo.  3.  800 x  480 DPI 240(Landscape)
echo.  4.  960 x  540 DPI 280(Landscape)
echo.  5. 1280 x  720 DPI 320(Landscape)
echo.  6. 1440 x  900 DPI 320(Landscape)
echo.  7. 1920 x 1080 DPI 480(Landscape)
echo. 
echo ------------- Vertical screen resolution presets -------------
echo.  8.  320 x  480 DPI 120(Portrait)
echo.  9.  360 x  640 DPI 160(Portrait)
echo. 10.  480 x  800 DPI 240(Portrait)
echo. 11.  540 x  960 DPI 280(Portrait)
echo. 12.  720 x 1280 DPI 320(Portrait)
echo. 13.  900 x 1440 DPI 320(Portrait)
echo. 14. 1080 x 1920 DPI 480(Portrait)
echo ------------------------------------------
echo.  0. ★★★★ Custom Resolution and DPI ★★★★
echo.
echo. Q. Back to Menu
echo.
echo. Droid4X Currently used resolution:%DefaultGraph%
echo.
set /p input="Please enter the number you want to perform the operation:"
echo ----------------------------------------
if /i "%input%"=="0" (
	echo.
	echo.===== Note =====
	echo. Since previously defined resolution, please fully understand the resolution and DPI!
	echo.
	echo. Simulator internal display resolution is not bound by the resolution, the window must be displayed in accordance with the display resolution.
	echo. If a custom resolution >= monitor resolution, if DPI suited, likely to cause abnormal display.
	echo.
	set /p width="Please enter the width:"
	set /p height="Please enter the height:"
	goto :ReInput
)
rem Landscape
if /i "%input%"=="1" call :Set_Pixels_DPI 480x320 120
if /i "%input%"=="2" call :Set_Pixels_DPI 640x360 160
if /i "%input%"=="3" call :Set_Pixels_DPI 800x480 240
if /i "%input%"=="4" call :Set_Pixels_DPI 960x540 280
if /i "%input%"=="5" call :Set_Pixels_DPI 1280x720 320
if /i "%input%"=="6" call :Set_Pixels_DPI 1440x900 320
if /i "%input%"=="7" call :Set_Pixels_DPI 1920x1080 480
rem Portrait
if /i "%input%"=="8" call :Set_Pixels_DPI 320x480 120
if /i "%input%"=="9" call :Set_Pixels_DPI 360x640 160
if /i "%input%"=="10" call :Set_Pixels_DPI 480x800 240
if /i "%input%"=="11" call :Set_Pixels_DPI 540x960 280
if /i "%input%"=="12" call :Set_Pixels_DPI 720x1280 320
if /i "%input%"=="13" call :Set_Pixels_DPI 900x1440 320
if /i "%input%"=="14" call :Set_Pixels_DPI 1080x1920 480
if /i "%input%"=="Q" cls && goto :menu
if not defined menu goto :Graph
cls
goto :Graph

:ReInput
echo.
if DEFINED width (
	echo %width%|findstr "^[0-9]*$">nul && (
		if DEFINED height (
			echo %height%|findstr "^[0-9]*$">nul && (
				set pixels=%width%x%height%-16
			) || (
				set /p height="Height numerical only, please re-enter:"
				goto :ReInput
			)
		) else (
			if /i "%input%"=="0" (
				set /p height="You did not enter height, please re-enter:"
				goto :ReInput
			)
		)
	) || (
		set /p width="Width numerical only, please re-enter:"
		goto :ReInput
	)
) else (
	if /i "%input%"=="0" (
		set /p width="You do not have to enter the width, please re-enter:"
		goto :ReInput
	)
)
echo.
echo You change the resolution as follows:%pixels%
echo.
echo ----------------------------------------
echo.
echo. Droid4X currently used resolution:%DefaultDPI%
echo.
:DPI
echo. Droid4X DPI currently used are:%DefaultDPI%
echo.
echo. DPI is the screen pixel density, if you do not know what is DPI, do not modify this value.
echo.If the resolution ^<1024 * 768, set the DPI is: 240.
echo.
if not defined DPI set /p DPI="Please enter DPI value:"
if DEFINED DPI (
	echo %DPI%|findstr "^[0-9]*$">nul || (
		set /p DPI="DPI numerical only, please re-enter:"
		goto :DPI
	)
) else (
	goto :DPI
)
echo You modify the DPI as follows:%DPI%
echo.
echo ----------------------------------------
echo.
:ok
CLS
echo.
echo ----------------------------------------
echo Droid4X currently used resolution:%DefaultGraph%
echo.
echo You change the resolution as follows:%pixels%
echo ----------------------------------------
echo.
echo ----------------------------------------
echo Droid4X DPI currently used are:%DefaultDPI%
echo.
echo You modify the DPI as follows:%DPI%
echo ----------------------------------------
echo.
set /p ok="Check to make sure the information is correct, enter [Y-correct/N-back to the menu]:"
if DEFINED ok (
	echo %ok%|findstr /i "Y" >nul 2>nul && (
		VBoxManage guestproperty set %ova% vbox_graph_mode %pixels%
		VBoxManage guestproperty set %ova% vbox_dpi %DPI%
		set DefaultDPI=%DPI%
		set DefaultGraph=%pixels%
		echo.
		echo Modification is completed, press any key and returned to the menu
		pause>nul
		cls
		goto :menu
	) || echo %ok%|findstr /i "N" >nul 2>nul && (
		cls
		goto :menu
	) || (
		cls
		goto :ok
	)
) else (
	cls
	goto :ok
)

:Memory
cls & title %title%----modify ram
echo. Current %ova% RAM:%Defaultmemory%
echo.
echo. ★ 1G=1024M, if memory greater than 4G, recommended RAM: 2048M, else 640M ~ 1024M.
echo. ★ Use less than 1G memory may make your emulator unstable or crash when playing game.
echo. ★ Make sure ram ^< memory
echo. ★ Default 1G ram is enough to run 3D game, pls assign approriately accrording to pc configration, max ram: 3.5G.
echo.
echo. ★ Input following number, auto ram conversion
echo.
echo.   [1 = 1024M]  [2 = 2048M]  [3 = 3500M] (Droid4X max ram)
echo.   [M = Back to Menu]
echo.
if not defined memory set /p memory="pls input ram(no unit):"
echo.
if not defined memory (
	goto :Memory
)
if /i "%memory%"=="1" set memory=1024
if /i "%memory%"=="2" set memory=2048
if /i "%memory%"=="3" set memory=3500
echo %memory%
if defined memory (
	if %memory% lss 512 (
		set /p memory="! (-_-) You want to run Droid4X? lowest 512M, re-enter it:"
		goto :Memory
	) else if %memory% GTR 3500 (
		set /p memory="(0_0) guy,it is wasted to assign so much ram, sugguest 1024 ~ 2048 enough￡~~type~~:"
		goto :Memory
	)
	echo %memory%|findstr "^[0-9]*$">nul && (
		VBoxManage modifyvm %ova% --memory %memory%
		echo.
		set Defaultmemory=%memory%
		echo. Modification is completed, the current memory to run:%memory%M, press any key to return to the menu.
		pause>nul
		cls
		goto :menu
	) || (
		set /p memory="Run memory value can only enter numbers, please re-enter:"
		goto :Memory
	)
)
cls
goto :Memory

:navBar
cls && set navBar=
echo.
echo. ----------========== Virtual soft key switch ==========----------
VBoxManage guestproperty get %ova% droid4x_force_navbar|findstr /i "No 0">nul &&(
echo Virtual softkey Status: Closed) || (echo virtual softkey Status: Open)
echo.
echo. 0. Close the Virtual soft key
echo. 1. Open the Virtual soft key
echo. M. Back to Menu
set /p navBar="Please enter the number you want to perform the operation:"
if "%navBar%"=="0" VBoxManage guestproperty set %ova% droid4x_force_navbar 0
if "%navBar%"=="1" VBoxManage guestproperty set %ova% droid4x_force_navbar 1
if /i "%navBar%"=="m" goto :menu
cls
goto :navBar

:CPU
cls && set modCPU=
echo.
echo. ----------========== CPU core count settings ==========----------
if not defined DefaulCPUCores CALL :info
echo.
IF /i "%VT%"=="off" (
	echo. Cause VT is disabled in BIOS, you cannot modify cpu counts. 
	set /p "vtopen=Please read VT enabled tutorial, confirm to open tutorial? [Y-open/empty-skip]:"
	if /i "!vtopen!"=="Y" start "" "http://www.droid4x.cn/bbs/forum.php?mod=redirect&goto=findpost&ptid=675&pid=2938&fromuid=46"
	goto :menu
)
if EXIST %windir%\SYSTEM32\wbem\wmic.exe (
	echo. The actual maximum CPU core threads:%DefaulCPUCores%
	echo. Droid4X used cores are:%DefaulLogical%
	echo.
) else (
	if EXIST "%~dp0wmic.exe" (
		call %~dp0wmic.exe exit
		goto :CPU
	) else (
		echo. Your computer lacks WMIC tests, please download the required procedures, and with this program in the same directory
		echo.
		echo. Download link: http://www.droid4x.cn/bbs/forum.php?mod=viewthread^&tid=13054
		echo.
		call :CopyUrl
		PAUSE && goto :menu
	)
)
echo. The number of cores will directly affect the speed of the simulator, if not special needs, do not change this value.

echo. A minimum of 1 cores, up to the actual number of CPU cores
echo.
echo. Caution!!No recommandation of assigning max cpu counts which will make PC work slowly
echo.
set /p "modCPU=Please enter the number you want to modify the core [M- return to the main menu]:"
if /i "%modCPU%"=="m" goto :menu
if not defined modCPU goto :cpu
echo %modCPU%|findstr /i "[0-9]*">nul 2>nul&& (
	if %modCPU% LSS 1 goto :cpu
	if %modCPU% GTR %DefaulCPUCores% goto :cpu
	"%VBoxManage%" modifyvm %ova% --cpus %modCPU%
	for /f "tokens=2 delims==" %%i in ('VBoxManage.exe showvminfo %ova% --machinereadable^|findstr /ir "CPUs"') do set DefaulLogical=%%i
	echo Modify success, the number of current core simulator is:%modCPU%
	pause
)
goto :CPU
pause

:Report
cls
call :Info
echo.
echo. ----------========== %ova% setting information ==========----------
echo.
echo. virtualbox OVA: %ova%
echo. 
echo. RAM: %Defaultmemory%
echo. 
echo. Resolution: %DefaultGraph%
echo.
echo. DPI: %DefaultDPI%
echo.
echo. CPU cores:% DefaulCPUCores%
echo. Droid4X used core: %DefaulLogical%
echo.
echo. Droid4X directory: %D4Path%
echo.
echo. VirtualBox directory: %VboxPath%
echo.
echo. Virtual soft key state: %navBarStart%
echo.
echo. adb port: %adbPort%
echo.
echo. VT acceleration: %VT%
echo.
echo. ----------======================================----------
echo.
echo. Press any key to return to the menu
pause>nul
goto :menu

:Devices
cls
echo.
echo. ----------========== Connected Android devices information ==========----------
echo.
"%D4Path%adb.exe" devices -l
echo. ----------========================================----------
goto :menuNocls

:checkPort
cls & title %title%--Droid4X startup abnormality check
echo.
echo -----===== Droid4X abnormality check =====-----
echo.
echo. The following features are customer service and technical support, ordinary users use under the guidance.
echo.
echo. 1. See %adbPort% port
echo. 2. See all ports 127.0.0.1
echo. 3. logcat Logging
echo. 4. See APK package names
echo. 5. pull out Logcat 
echo. 0. Back to the menu
echo.
echo. ----------=====================----------
echo.
set checkPort=
set /p checkPort="Please enter the number you want to perform the operation:"
if /i "%checkPort%"=="1" netstat -ano|findstr %adbPort% && pause>nul
if /i "%checkPort%"=="2" netstat -ano|findstr 127.0.0.1* && pause>nul
if /i "%checkPort%"=="3" %adb% shell logcat -s ActivityManager
if /i "%checkPort%"=="4" goto :package
if /i "%checkPort%"=="5" (
		del /q /f %Desktop%\Droid4X_RunLog.log
		echo. Started logging
		echo. Logging position on the desktop, the file name: Droid4X_RunLog.log
		echo. If you need to end the logging, press Ctrl + C, and in the pop-up prompt, select N.
		%adb% shell logcat -v time -d -s ActivityManager>>%Desktop%\Droid4X_RunLog.log
		goto :checkPort
)
if /i "%checkPort%"=="0" goto :menu
goto :checkPort

:package
set InstallData=
set /p InstallData="Please drag APK files to this window:"
echo.
if /i "%InstallData%"=="M" GOTO :checkPort
if defined InstallData (
	echo %InstallData%
	%D4Path%\aapt.exe d badging %InstallData% | grep 'package:'
)
pause
goto :package

:log
CLS
echo.
echo. update link: http://www.colafile.com/u/%%E6%%9E%%81%%E5%%93%%81%%E5%%B0%%8F%%E7%%8C%%AB
set /p updata="if wanna update, pls input[Y-update/empty-back to main menu]:"
if /i "%updata%"=="Y" (start "" "http://www.colafile.com/u/极品小猫")
cls
goto :menu


Rem ========== Callback ==========

:info
echo Getting basic information %ova%...
for /f "tokens=2" %%i in ('VBoxManage.exe guestproperty get %ova% vbox_graph_mode') do (
	rem get resolution
	set DefaultGraph=%%i
) & for /f "tokens=2" %%i in ('VBoxManage.exe guestproperty get %ova% vbox_dpi') do (
	rem get DPI
	set DefaultDPI=%%i
) & for /f "tokens=2 delims==" %%i in ('VBoxManage.exe showvminfo %ova% --machinereadable^|findstr /ir "^memory"') do (
	rem get ram
	set Defaultmemory=%%i
) & for /f "tokens=2 delims==" %%i in ('VBoxManage.exe showvminfo %ova% --machinereadable^|findstr /ir "^CPUs"') do (
	rem get cpu cores
	set DefaulLogical=%%i
) & for /f "tokens=2 delims==" %%i in ('VBoxManage.exe showvminfo %ova% --machinereadable^|findstr /ir "^VT"') do (
	rem get VT state
	set VT=%%~i
) & if EXIST %windir%\SYSTEM32\wbem\wmic.exe (
	for /f "skip=1" %%i in ('wmic cpu get NumberOfLogicalProcessors^|findstr /r .') do (
		rem max physics cpu cores
		set DefaulCPUCores=%%i
	)
) & VBoxManage guestproperty get %ova% droid4x_force_navbar|findstr /i "No 0">nul &&(
	set navBarStart=off
	) || (set navBarStart=on)
:Port
for /f "tokens=4 delims=," %%i in ('VBoxManage showvminfo %ova% --machinereadable^|findstr /i "ADB_PORT"') do (
	rem	get adb port
	set adbPort=%%i
) 
:connectAdb
"%D4Path%\adb.exe" connect 127.0.0.1:%adbPort%>nul
exit /b

:Set_Pixels_DPI
echo Y
set pixels=%1-16
set DPI=%2
goto :ok

:Format
set ova=droid4x
set VBoxManage=%VboxPath%VBoxManage.exe
for /f "tokens=2,*" %%i in ('"reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Desktop 2>nul"') do (
	rem get desktop path
	set Desktop="%%j"
)
exit /b

:resetMap
netsh winsock reset|findstr "administrator" && echo current user has no enough privilege , pls switch to admin account, or close UAC (google if no noting about it)||echo reset  Winsock contents successfully, you must reboot your computer to finish reseting.
pause
exit /b

:ConnectDroid4X
echo Reconnect the Droid4X
"%D4Path%\adb.exe" connect 127.0.0.1:%adbPort%
%adb% shell mount -o,remount rw /system
echo.
exit/b

:RemountSD
call :ConnectDroid4x
%adb%  remount
echo SD card has been remount, try again to open the SD card catalog in the simulator
pause
exit/b

:CopyUrl
echo.
echo. (copy method: right click -> mark it -> select link -> right click -> copy done)
exit/b

:listVMS
cls
echo.
title %title%--Switch multi Droid4X
set ovaNum=
echo. If you are not sure to modify which emulator, pls modify according to sequence in multi mgr
echo. -----===== multi ova list =====-----
echo. droid4x
for /f "skip=1 delims= " %%i in ('VBoxManage list vms^|findstr /i "Droid4X"') do (
	echo. %%~i
)
echo. -----=====---------------------=====-----
echo. current emulator is : %ova%
echo.
set /p ovaNum="pls input the end number in each line(0 is default emulator)"
if defined ovaNum (
	if /i "%ovaNum%"=="0" (
		set newova=droid4x
	) else (
		set newova=droid4x_%ovaNum%
	)
	VBoxManage showvminfo !newova! --machinereadable>nul 2>nul&&(
	echo. modify target :!newova!
	call :Port
	)||echo. !newova! no such emulator,pls input again && pause && goto :listVMS
	pause
	set ova=!newova!
)
echo.
exit/b


rem ===== Q =====
:FixedRoot
call :connectAdb
%adb% remount
%adb% shell rm -rf /system/bin/su
echo. clear su done, pls restart Droid4X
pause
exit/b

:pause
pause>nul