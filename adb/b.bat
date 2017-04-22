echo on

.\adb\adb connect 127.0.0.1:26944:5037
.\adb\adb devices 
.\adb\adb forward tcp:7000 tcp:7000
.\adb\adb forward tcp:7001 tcp:7001

pause
exit