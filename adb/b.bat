echo on


adb connect localhost
adb devices 
adb forward tcp:7000 tcp:7000
adb forward tcp:7001 tcp:7001


pause