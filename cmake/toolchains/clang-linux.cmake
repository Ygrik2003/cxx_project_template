include(${CMAKE_CURRENT_LIST_DIR}/common.cmake)

set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
# Global use mold linker
add_link_options(-lc++abi)
