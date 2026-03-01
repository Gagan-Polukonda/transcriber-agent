#!/bin/bash
# Android NDK Setup Script for macOS

echo "======================================"
echo "Android NDK Installation Guide"
echo "======================================"
echo ""

# Check if Android Studio is installed
if ! command -v android &> /dev/null; then
    echo "❌ Android Studio not found or not in PATH"
    echo ""
    echo "Steps to install:"
    echo "1. Download Android Studio from: https://developer.android.com/studio"
    echo "2. Install Android Studio"
    echo "3. Run this script again"
    exit 1
fi

echo "✓ Android Studio is available"
echo ""

# Check for SDK location
SDK_LOCATION="$HOME/Library/Android/sdk"
if [ ! -d "$SDK_LOCATION" ]; then
    echo "❌ Android SDK not found at: $SDK_LOCATION"
    echo ""
    echo "To fix:"
    echo "1. Open Android Studio"
    echo "2. Go to: Android Studio → Preferences → Languages & Frameworks → Android SDK"
    echo "3. Copy the SDK Location path"
    echo "4. The default should be: ~/Library/Android/sdk"
    exit 1
fi

echo "✓ Android SDK found at: $SDK_LOCATION"
echo ""

# Use sdkmanager to install NDK
echo "Installing Android NDK..."
echo "(This may take 5-10 minutes)"
echo ""

# Find sdkmanager
SDKMANAGER="$SDK_LOCATION/cmdline-tools/latest/bin/sdkmanager"

if [ ! -f "$SDKMANAGER" ]; then
    echo "❌ sdkmanager not found. Installing cmdline-tools first..."
    echo ""
    echo "Steps:"
    echo "1. Open Android Studio"
    echo "2. Go to: Settings → Languages & Frameworks → Android SDK → SDK Tools"
    echo "3. Install 'Android SDK Command-line Tools (latest)'"
    echo "4. Run this script again"
    exit 1
fi

echo "✓ Found sdkmanager"
echo ""

# Install latest NDK
echo "Installing NDK..."
"$SDKMANAGER" "ndk;27.0.12077973"

echo ""
echo "======================================"
echo "✓ Android NDK Installation Complete!"
echo "======================================"
echo ""
echo "Verify installation:"
ls -la "$SDK_LOCATION/ndk/"
