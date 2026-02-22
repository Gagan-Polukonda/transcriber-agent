#!/bin/bash

set -e

echo "=========================================="
echo "Voice to Text - Build Setup Script"
echo "=========================================="

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 not found${NC}"
        return 1
    fi
    echo -e "${GREEN}✓ $1 found${NC}"
    return 0
}

echo ""
echo "Checking prerequisites..."
check_tool "flutter" || { echo "Please install Flutter"; exit 1; }
check_tool "cmake" || { echo "Please install CMake"; exit 1; }

if [ "$(uname)" == "Darwin" ]; then
    check_tool "xcode-select" || { echo "Please install Xcode Command Line Tools"; exit 1; }
fi

echo ""
echo "Setting up Flutter project..."
cd app
echo "Getting dependencies..."
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"

cd ..

echo ""
echo "Checking for whisper.cpp..."
if [ ! -d "native/whisper.cpp" ]; then
    echo "Cloning whisper.cpp..."
    git clone https://github.com/ggerganov/whisper.cpp.git native/whisper.cpp
    echo -e "${GREEN}✓ whisper.cpp cloned${NC}"
else
    echo -e "${GREEN}✓ whisper.cpp already present${NC}"
fi

echo ""
echo "Building native Whisper bridge..."
mkdir -p native/build
cd native/build

echo "Running CMake..."
cmake ..

echo "Compiling..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
echo -e "${GREEN}✓ Native library built${NC}"

cd ../..

# Copy dylib to a location the app can find
if [ "$(uname)" == "Darwin" ]; then
    echo ""
    echo "Installing dylib for macOS..."
    cp native/build/whisper_bridge.dylib /usr/local/lib/ 2>/dev/null || {
        echo -e "${YELLOW}Could not copy to /usr/local/lib (try with sudo)${NC}"
        echo "  sudo cp native/build/whisper_bridge.dylib /usr/local/lib/"
    }
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Download a Whisper model (tiny is fastest, ~75MB):"
echo "   mkdir -p models"
echo "   curl -L -o models/ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
echo ""
echo "2. Copy the model to the app's documents directory:"
echo "   mkdir -p ~/Library/Containers/com.example.voiceToTextLocal/Data/Documents/whisper_models/"
echo "   cp models/ggml-base.bin ~/Library/Containers/com.example.voiceToTextLocal/Data/Documents/whisper_models/"
echo ""
echo "3. Run the app:"
echo "   cd app"
echo "   flutter run -d macos"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
