add_library(template_coverage INTERFACE)
target_compile_options(
    template_coverage
    INTERFACE -fprofile-instr-generate -fcoverage-mapping
)
target_link_options(
    template_coverage
    INTERFACE -fprofile-instr-generate -fcoverage-mapping
)
add_library(template::coverage ALIAS template_coverage)

add_library(template_base INTERFACE)
target_compile_definitions(
    template_base
    INTERFACE TEMPLATE_$<STRING:TOUPPER,$<PLATFORM_ID>>
)
target_compile_options(
    template_base
    INTERFACE -Werror -Wpedantic -Wall $<$<CXX_COMPILER_ID:GNU>:-freflection>
)
target_link_libraries(
    template_base
    INTERFACE $<$<BOOL:$ENV{TLT_COVERAGE}>:template::coverage>
)

add_library(template::base ALIAS template_base)
