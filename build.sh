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
echo "Building native Whisper bridge..."
mkdir -p native/build
cd native/build

echo "Running CMake..."
cmake ..

echo "Compiling..."
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)
echo -e "${GREEN}✓ Native library built${NC}"

cd ../..

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Download Whisper models:"
echo "   mkdir -p models"
echo "   # Download ggml-tiny.bin, ggml-base.bin, or ggml-small.bin from HuggingFace"
echo ""
echo "2. Run the app:"
echo "   cd app"
echo "   flutter run"
echo ""
echo -e "${GREEN}Setup complete!${NC}"
