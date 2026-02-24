#!/bin/bash
# Patch whisper.cpp CMakeLists.txt to force static library build on Android
# This script is run automatically during the Flutter build process

WHISPER_CMAKE="${BASH_SOURCE%/*}/whisper.cpp/CMakeLists.txt"

if [ ! -f "$WHISPER_CMAKE" ]; then
    echo "Error: whisper.cpp/CMakeLists.txt not found at $WHISPER_CMAKE"
    exit 1
fi

# Check if patch is already applied
if grep -q "ANDROID_STATIC_PATCH" "$WHISPER_CMAKE" 2>/dev/null; then
    echo "Whisper.cpp already patched for Android static linking"
    exit 0
fi

# Apply patch: add Android-specific BUILD_SHARED_LIBS_DEFAULT = OFF
# This ensures static library is built on Android for embedding in JNI
if grep -q "if (EMSCRIPTEN)" "$WHISPER_CMAKE"; then
    # Create temporary file with patch applied
    cp "$WHISPER_CMAKE" "$WHISPER_CMAKE.bak"

    # Add Android section after EMSCRIPTEN section
    sed -i '/^elseif(EMSCRIPTEN)/a\
elseif(ANDROID)\
    # ANDROID_STATIC_PATCH: Force static library for embedding in JNI\
    set(BUILD_SHARED_LIBS_DEFAULT OFF)' "$WHISPER_CMAKE" || {
        # If sed fails, restore backup
        mv "$WHISPER_CMAKE.bak" "$WHISPER_CMAKE"
        echo "Error: Failed to patch CMakeLists.txt"
        exit 1
    }

    # Replace the option() call to force static on Android
    awk '
    BEGIN { found=0 }
    /^option\(BUILD_SHARED_LIBS/ && !found {
        print "if(ANDROID)"
        print "    set(BUILD_SHARED_LIBS OFF CACHE BOOL \"build shared libraries\" FORCE)"
        print "else()"
        print $0
        print "endif()"
        found=1
        next
    }
    { print }
    ' "$WHISPER_CMAKE" > "$WHISPER_CMAKE.tmp" && mv "$WHISPER_CMAKE.tmp" "$WHISPER_CMAKE"

    echo "Patched whisper.cpp CMakeLists.txt for Android static linking"
else
    echo "Error: Could not find expected CMakeLists.txt structure"
    exit 1
fi
