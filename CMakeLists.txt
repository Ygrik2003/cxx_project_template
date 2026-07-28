cmake_minimum_required(VERSION 4.4.0 FATAL_ERROR)

project(
    template
    VERSION 0.0.1.0
    DESCRIPTION "blah blah blah"
    HOMEPAGE_URL "http://localhost:8080"
    LANGUAGES C CXX
)

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(
        FATAL_ERROR
        "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there."
    )
endif()

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(options REQUIRED NO_CMAKE_FIND_ROOT_PATH)
find_package(functions REQUIRED NO_CMAKE_FIND_ROOT_PATH)
find_package(base REQUIRED NO_CMAKE_FIND_ROOT_PATH)

add_subdirectory(external)

# Skip external
set(CMAKE_CXX_MODULE_STD ON)

add_subdirectory(src)
add_subdirectory(example)
