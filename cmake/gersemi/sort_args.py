# https://github.com/BlankSpruce/gersemi/blob/master/extension-example/as_module/gersemi_extension_example/__init__.py

from gersemi.builtin_commands import builtin_commands

modified_target_sources = builtin_commands["target_sources"]
modified_target_sources["keyword_preprocessors"] = dict.fromkeys(
    modified_target_sources["multi_value_keywords"], "sort+unique"
)

modified_target_link_libraries = builtin_commands["target_link_libraries"]
modified_target_link_libraries["keyword_preprocessors"] = dict.fromkeys(
    modified_target_link_libraries["multi_value_keywords"], "sort+unique"
)

command_definitions = {
    "target_sources": modified_target_sources,
    "target_link_libraries": modified_target_link_libraries,
}
