if(CMAKE_SYSTEM_NAME STREQUAL "Android")
    add_library(example SHARED)
else()
    add_executable(example)
endif()

target_sources(example PRIVATE example.cxx)
target_link_libraries(example PRIVATE template::template template::base)
