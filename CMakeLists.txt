cmake_minimum_required(VERSION 4.3 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_UNITY_BUILD OFF)
set(CMAKE_UNITY_BUILD_BATCH_SIZE 32)
set(CMAKE_CONFIGURATION_TYPES Debug Release RelWithDebInfo MinSizeRel)

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)

set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "451f2fe2-a8a2-47c3-bc32-94786d8fc91b")
set(CMAKE_CXX_MODULE_STD 1)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
# Global use mold linker
add_link_options(-fuse-ld=mold)
add_link_options(-lc++abi)

project(
    template
    VERSION 0.0.1.0
    DESCRIPTION "blah blah blah"
    HOMEPAGE_URL "http://localhost"
    LANGUAGES C CXX
)

if(NOT ${CMAKE_CXX_STANDARD} IN_LIST CMAKE_CXX_COMPILER_IMPORT_STD)
    message(
        FATAL_ERROR
        "For build this project needed cxx23 support or higher. Install clang 19+ and newer libc++"
    )
endif()

list(APPEND CMAKE_PREFIX_PATH ${CMAKE_SOURCE_DIR}/cmake)

find_package(options REQUIRED)

add_library(template_base INTERFACE)
target_compile_definitions(
    template_base
    INTERFACE $<$<PLATFORM_ID:Linux>:TEMPLATE_LINUX>
)
target_compile_options(
    template_base
    INTERFACE
        -Werror
        -Wpedantic
        -Wall
        $<$<BOOL:${TEMPLATE_COVERAGE}>:
        -fprofile-instr-generate
        -fcoverage-mapping
        >
)
target_link_options(
    template_base
    INTERFACE
        $<$<BOOL:${TEMPLATE_COVERAGE}>:
        -fprofile-instr-generate
        -fcoverage-mapping
        >
)
add_library(template::base ALIAS template_base)

add_subdirectory(external)
add_subdirectory(src)
add_subdirectory(example)
