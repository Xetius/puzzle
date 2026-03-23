#!/usr/bin/env bash
set -euo pipefail

ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"
export ANDROID_HOME
export ANDROID_AVD_HOME="$HOME/.config/.android/avd"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

AVD_NAME="pixel9a"
SYSTEM_IMAGE="system-images;android-34;google_apis;arm64-v8a"
DEVICE="pixel_9a"

# Install emulator and system image if missing
if [ ! -d "$ANDROID_HOME/emulator" ]; then
  echo "Installing Android emulator..."
  sdkmanager "emulator"
fi

if [ ! -d "$ANDROID_HOME/system-images/android-34/google_apis/arm64-v8a" ]; then
  echo "Installing system image..."
  sdkmanager "$SYSTEM_IMAGE"
fi

# Create AVD if it doesn't exist
if ! avdmanager list avd -c 2>/dev/null | grep -q "^${AVD_NAME}$"; then
  echo "Creating AVD: $AVD_NAME"
  echo "no" | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" -d "$DEVICE"
fi

# Launch emulator if not already running
if ! adb devices 2>/dev/null | grep -q "emulator"; then
  echo "Starting emulator..."
  emulator -avd "$AVD_NAME" > /dev/null 2>&1 &
  echo "Waiting for emulator to boot..."
  adb wait-for-device
  adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done'
  echo "Emulator ready."
else
  echo "Emulator already running."
fi

echo "Running Flutter app..."
flutter pub get
flutter run
