#! /bin/bash
# Note:   This script is used install the generated APK to the connected Android device.
# Author: Stefanos Laskaridis (stefanos@brave.com)

echo "Assuming you have generated signed APK through Android Studio"
sleep 2

echo "Installing ../android/app/debug/app-debug.apk to device"
adb install ../android/app/debug/app-debug.apk

