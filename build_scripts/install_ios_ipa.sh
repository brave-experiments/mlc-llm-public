#! /bin/bash
# Note:   This script is used install the generated .ipa to the connected iOS device.
# Author: Stefanos Laskaridis (stefanos@brave.com)

ROOT_DIR=$(ROOT_DIR:-"/tmp")

echo "Assuming you have generated signed IPA through XCode"
sleep 2

echo "Installing $ROOT_DIR/MLCChat.ipa to device"
ideviceinstaller -g $ROOT_DIR/MLCChat.ipa

