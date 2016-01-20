echo on

.\adb\adb connect localhost
.\adb\adb devices 
.\adb\adb forward tcp:7000 tcp:7000
.\adb\adb forward tcp:7001 tcp:7001

exit