#!/bin/bash
set -e

case "$1" in
  develop)
    echo "Running in development mode (SERVER_URL from .env)..."
    flutter run
    ;;
  install)
    echo "Building production APK (server: https://author.isebarn.com)..."
    flutter build apk --release --dart-define=SERVER_URL=https://author.isebarn.com
    echo "Installing on connected device..."
    adb install -r build/app/outputs/flutter-apk/app-release.apk
    echo "Done."
    ;;
  *)
    echo "Usage: ./mobile.sh [develop|install]"
    echo "  develop  - Run debug build using SERVER_URL from .env"
    echo "  install  - Build release APK and install via adb (uses author.isebarn.com)"
    exit 1
    ;;
esac
