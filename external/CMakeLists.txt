include(${CMAKE_SOURCE_DIR}/cmake/CPM.cmake)

set(CPM_USE_LOCAL_PACKAGES ON)

CPMAddPackage(
    NAME SDL3
    GITHUB_REPOSITORY libsdl-org/SDL
    GIT_TAG release-3.4.12

    OPTIONS
        "SDL_STATIC OFF"
        "SDL_SHARED ON"
        "SDL_TESTS OFF"
        "SDL_WAYLAND ON"
        "SDL_DISABLE_INSTALL ON"

    FIND_PACKAGE_ARGUMENTS GLOBAL
)

# CPMAddPackage(
#     NAME json
#     GITHUB_REPOSITORY nlohmann/json
#     VERSION 3.12.0
#     FIND_PACKAGE_ARGUMENTS GLOBAL
# )

# CPMAddPackage(
#     NAME fmt
#     GITHUB_REPOSITORY fmtlib/fmt
#     VERSION 11.2.0
#     FIND_PACKAGE_ARGUMENTS GLOBAL
# )