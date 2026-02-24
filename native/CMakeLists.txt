cmake_minimum_required(VERSION 3.10)
project(whisper_bridge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build options
option(WHISPER_SUPPORT_OPENBLAS "Support OpenBLAS" OFF)
option(WHISPER_SUPPORT_COREML "Support CoreML" OFF)
option(WHISPER_CUDA "Build with CUDA support" OFF)

# For Android, force static linking for whisper.cpp
if(ANDROID)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build as static library" FORCE)
    # Override the option in whisper.cpp before it processes it
    set(BUILD_SHARED_LIBS OFF)
    # Disable tests and examples for faster build
    set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
endif()

# Find required packages
find_package(Threads REQUIRED)

# Add whisper.cpp as subdirectory (must be cloned into native/whisper.cpp/)
add_subdirectory(whisper.cpp)

# Bridge source
set(WHISPER_SOURCES whisper_bridge.cpp)

# For Android, build as shared library but link whisper statically
# For other platforms, build as shared library
add_library(whisper_bridge SHARED ${WHISPER_SOURCES})

# Link whisper library from whisper.cpp build
# On Android, whisper is built as static and will be embedded in whisper_bridge.so
if(ANDROID)
    # Force static linking by using the static library directly
    target_link_libraries(whisper_bridge PRIVATE Threads::Threads whisper -static)
else()
    target_link_libraries(whisper_bridge PRIVATE Threads::Threads whisper)
endif()

# Include whisper.cpp headers
target_include_directories(whisper_bridge PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp
)

# Platform-specific suffix
if(APPLE AND NOT IOS)
    set_target_properties(whisper_bridge PROPERTIES
        PREFIX ""
        SUFFIX ".dylib"
    )
elseif(UNIX AND NOT APPLE)
    set_target_properties(whisper_bridge PROPERTIES
        PREFIX ""
        SUFFIX ".so"
    )
endif()

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
