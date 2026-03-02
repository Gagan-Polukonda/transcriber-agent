cmake_minimum_required(VERSION 3.10)
project(voice_to_text_local)

# Build the whisper bridge native library
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Debug: show resolved paths so build issues are easier to diagnose
message(STATUS "[DEBUG] CMAKE_CURRENT_SOURCE_DIR = ${CMAKE_CURRENT_SOURCE_DIR}")
message(STATUS "[DEBUG] Native source dir = ${CMAKE_CURRENT_SOURCE_DIR}/../../../native")
get_filename_component(_NATIVE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../native" ABSOLUTE)
message(STATUS "[DEBUG] Native source dir (resolved) = ${_NATIVE_DIR}")
if(NOT EXISTS "${_NATIVE_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "[DEBUG] CMakeLists.txt NOT FOUND at ${_NATIVE_DIR}. "
        "Expected native/CMakeLists.txt relative to repo root.")
endif()

# Add the native bridge library from the parent project
add_subdirectory(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../native
    ${CMAKE_CURRENT_BINARY_DIR}/whisper_bridge
)

# The target 'whisper_bridge' is now available for Flutter to link against
