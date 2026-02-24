cmake_minimum_required(VERSION 3.10)
project(whisper_bridge)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Build options
option(WHISPER_SUPPORT_OPENBLAS "Support OpenBLAS" OFF)
option(WHISPER_SUPPORT_COREML "Support CoreML" OFF)
option(WHISPER_CUDA "Build with CUDA support" OFF)

# On Android, apply build-time patch to ensure whisper builds as static library
if(ANDROID)
    set(WHISPER_CMAKE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp/CMakeLists.txt")
    if(EXISTS "${WHISPER_CMAKE_PATH}" AND NOT WHISPER_CMAKE_PATCHED)
        # Read the CMakeLists.txt file
        file(READ "${WHISPER_CMAKE_PATH}" WHISPER_CMAKE_CONTENT)

        # Check if patch needs to be applied
        if(NOT WHISPER_CMAKE_CONTENT MATCHES "ANDROID_STATIC_PATCH")
            message(STATUS "Applying Android static linking patch to whisper.cpp...")

            # Add Android conditional after EMSCRIPTEN section
            string(REPLACE
                "else()\n    if (MINGW)"
                "elseif(ANDROID)\n    # ANDROID_STATIC_PATCH: Force static library for embedding in JNI\n    set(BUILD_SHARED_LIBS_DEFAULT OFF)\nelse()\n    if (MINGW)"
                WHISPER_CMAKE_CONTENT "${WHISPER_CMAKE_CONTENT}")

            # Force BUILD_SHARED_LIBS OFF on Android in the option() call
            string(REPLACE
                "option(BUILD_SHARED_LIBS \"build shared libraries\" \${BUILD_SHARED_LIBS_DEFAULT})"
                "if(ANDROID)\n    set(BUILD_SHARED_LIBS OFF CACHE BOOL \"build shared libraries\" FORCE)\nelse()\n    option(BUILD_SHARED_LIBS \"build shared libraries\" \${BUILD_SHARED_LIBS_DEFAULT})\nendif()"
                WHISPER_CMAKE_CONTENT "${WHISPER_CMAKE_CONTENT}")

            # Write back the patched content
            file(WRITE "${WHISPER_CMAKE_PATH}" "${WHISPER_CMAKE_CONTENT}")
            set(WHISPER_CMAKE_PATCHED TRUE CACHE BOOL "" FORCE)
            message(STATUS "Whisper.cpp patched successfully")
        endif()
    endif()

    # Force static build options
    set(BUILD_SHARED_LIBS OFF)
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
target_link_libraries(whisper_bridge PRIVATE Threads::Threads whisper)

# On Android, ensure static library is embedded in the shared library
if(ANDROID)
    # Use linker script to embed whisper.a completely into whisper_bridge.so
    target_link_options(whisper_bridge PRIVATE
        "LINKER:--whole-archive"
        "LINKER:-Bstatic"
    )
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
