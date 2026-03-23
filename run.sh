#!/usr/bin/env bash
set -euo pipefail

ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_HOME
export ANDROID_AVD_HOME="$HOME/.config/.android/avd"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

AVD_NAME="pixel9a"

# Launch emulator if not already running
if ! adb devices 2>/dev/null | grep -q "emulator"; then
  echo "Starting emulator..."
  emulator -avd "$AVD_NAME" -no-snapshot-load > /dev/null 2>&1 &
  echo "Waiting for emulator to boot..."
  adb wait-for-device
  adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
  echo "Emulator ready."
else
  echo "Emulator already running."
fi

echo "Installing dependencies..."
flutter pub get

echo "Running app..."
flutter run -d emulator
