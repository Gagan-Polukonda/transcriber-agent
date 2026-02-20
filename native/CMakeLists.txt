cmake_minimum_required(VERSION 3.10)
project(whisper_bridge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add whisper.cpp as subdirectory
# You'll need to clone whisper.cpp separately and point to it
# For now, we assume it's in ../whisper.cpp

# Build options
option(WHISPER_SUPPORT_OPENBLAS "Support OpenBLAS" OFF)
option(WHISPER_SUPPORT_COREML "Support CoreML" OFF)
option(WHISPER_CUDA "Build with CUDA support" OFF)

# Find required packages
find_package(Threads REQUIRED)

# Whisper.cpp source files (subset needed for transcription)
set(WHISPER_SOURCES
    whisper_bridge.cpp
    # Add whisper.cpp main sources if building from source
    # ${WHISPER_CPP_DIR}/whisper.cpp
)

# Create shared library for Android
if(ANDROID)
    add_library(whisper_bridge SHARED ${WHISPER_SOURCES})
    target_link_libraries(whisper_bridge PRIVATE Threads::Threads)
    # Link against pre-built whisper.a if available
    # target_link_libraries(whisper_bridge PRIVATE ${WHISPER_CPP_DIR}/libwhisper.a)
endif()

# Create shared library for macOS
if(APPLE AND NOT IOS)
    add_library(whisper_bridge SHARED ${WHISPER_SOURCES})
    target_link_libraries(whisper_bridge PRIVATE Threads::Threads)
    set_target_properties(whisper_bridge PROPERTIES
        PREFIX ""
        SUFFIX ".dylib"
    )
endif()

# Create shared library for Linux
if(UNIX AND NOT APPLE AND NOT ANDROID)
    add_library(whisper_bridge SHARED ${WHISPER_SOURCES})
    target_link_libraries(whisper_bridge PRIVATE Threads::Threads)
    set_target_properties(whisper_bridge PROPERTIES
        PREFIX ""
        SUFFIX ".so"
    )
endif()

# Include directories
target_include_directories(whisper_bridge PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Compiler flags
if(MSVC)
    target_compile_options(whisper_bridge PRIVATE /W4)
else()
    target_compile_options(whisper_bridge PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Install targets
install(TARGETS whisper_bridge
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)
