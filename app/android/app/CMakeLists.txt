cmake_minimum_required(VERSION 3.10)
project(voice_to_text_local)

# Build the whisper bridge native library
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the native bridge library from the parent project
add_subdirectory(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../..
    ${CMAKE_CURRENT_BINARY_DIR}/whisper_bridge
)

# The target 'whisper_bridge' is now available for Flutter to link against
