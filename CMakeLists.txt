cmake_minimum_required(VERSION 4.3.3 FATAL_ERROR)

project(
    template
    VERSION 0.0.1.0
    DESCRIPTION "blah blah blah"
    HOMEPAGE_URL "http://localhost"
    LANGUAGES C CXX
)

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
