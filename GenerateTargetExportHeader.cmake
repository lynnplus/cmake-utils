
#[=======================================================================[.rst:
GenerateExportHeader
--------------------

   GENERATE_EXPORT_HEADER(LIBRARY_TARGET
             [BASE_NAME <base_name>]
             [EXPORT_MACRO_NAME <export_macro_name>]
             [EXPORT_FILE_NAME <export_file_name>]
             [DEPRECATED_MACRO_NAME <deprecated_macro_name>]
             [NO_EXPORT_MACRO_NAME <no_export_macro_name>]
             [INCLUDE_GUARD_NAME <include_guard_name>]
             [STATIC_DEFINE <static_define>]
             [EXPORT_IMPORT_CONDITION <export_import_condition>(default: read prop DEFINE_SYMBOL for target)]
             [PREFIX_NAME <prefix_name>]
             [CUSTOM_CONTENT_FROM_VARIABLE <variable>]
   )

example:
.. code-block:: cmake

   set(CMAKE_CXX_VISIBILITY_PRESET hidden)
   set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
   add_library(somelib someclass.cpp)
   generate_export_header(somelib)
   install(TARGETS somelib DESTINATION ${LIBRARY_INSTALL_DIR})
   install(FILES
    someclass.h
    ${PROJECT_BINARY_DIR}/somelib_export.h DESTINATION ${INCLUDE_INSTALL_DIR}
   )
#]=======================================================================]

get_filename_component(_GTEH_FILE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)

function(generate_target_export_header TARGET_LIBRARY)
    get_property(type TARGET ${TARGET_LIBRARY} PROPERTY TYPE)
    if(NOT ${type} STREQUAL "STATIC_LIBRARY"
            AND NOT ${type} STREQUAL "SHARED_LIBRARY"
            AND NOT ${type} STREQUAL "OBJECT_LIBRARY"
            AND NOT ${type} STREQUAL "MODULE_LIBRARY")
        message(WARNING "This macro can only be used with libraries")
        return()
    endif()

    set(oneValueArgs PREFIX_NAME BASE_NAME EXPORT_MACRO_NAME EXPORT_FILE_NAME
            DEPRECATED_MACRO_NAME NO_EXPORT_MACRO_NAME STATIC_DEFINE
            CUSTOM_CONTENT_FROM_VARIABLE INCLUDE_GUARD_NAME EXPORT_IMPORT_CONDITION)

    cmake_parse_arguments(_GTEH "" "${oneValueArgs}" "" ${ARGN})
    if(_GTEH_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unknown keywords given to GENERATE_EXPORT_HEADER(): \"${_GTEH_UNPARSED_ARGUMENTS}\"")
    endif()

    if (NOT _GTEH_BASE_NAME)
        set(_GTEH_BASE_NAME "${TARGET_LIBRARY}")
    endif ()
    string(TOUPPER ${_GTEH_BASE_NAME} BASE_NAME_UPPER)
    string(TOLOWER ${_GTEH_BASE_NAME} BASE_NAME_LOWER)

    macro(check_def_var _name _dv _out)
        if (NOT ${_name})
            set(${_out} ${_dv})
        else ()
            set(${_out} ${_GTEH_PREFIX_NAME}${${_name}})
        endif ()
        string(MAKE_C_IDENTIFIER ${${_out}} ${_out})
    endmacro()

    set(LIB_MACRO_NAME "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}")

    check_def_var(_GTEH_EXPORT_MACRO_NAME "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}_EXPORT" EXPORT_MACRO_NAME)
    check_def_var(_GTEH_NO_EXPORT_MACRO_NAME "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}_NO_EXPORT" NO_EXPORT_MACRO_NAME)
    check_def_var(_GTEH_DEPRECATED_MACRO_NAME "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}_DEPRECATED" DEPRECATED_MACRO_NAME)
    check_def_var(_GTEH_STATIC_DEFINE "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}_STATIC_DEFINE" STATIC_DEFINE)
    check_def_var(_GTEH_INCLUDE_GUARD_NAME "${_GTEH_PREFIX_NAME}${BASE_NAME_UPPER}_EXPORT_H" INCLUDE_GUARD_NAME)

    set(EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/${BASE_NAME_LOWER}_export.h")
    if(_GTEH_EXPORT_FILE_NAME)
        if(IS_ABSOLUTE ${_GTEH_EXPORT_FILE_NAME})
            set(EXPORT_FILE_NAME ${_GTEH_EXPORT_FILE_NAME})
        else()
            set(EXPORT_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/${_GTEH_EXPORT_FILE_NAME}")
        endif()
    endif()

    set(EXPORT_IMPORT_CONDITION ${TARGET_LIBRARY}_EXPORTS)
    get_target_property(_define_symbol ${TARGET_LIBRARY} DEFINE_SYMBOL)
    if (_GTEH_EXPORT_IMPORT_CONDITION)
        set(EXPORT_IMPORT_CONDITION ${_GTEH_EXPORT_IMPORT_CONDITION})
    elseif (_define_symbol)
        set(EXPORT_IMPORT_CONDITION ${_define_symbol})
    endif ()
    string(MAKE_C_IDENTIFIER ${EXPORT_IMPORT_CONDITION} EXPORT_IMPORT_CONDITION)

    if(_GTEH_CUSTOM_CONTENT_FROM_VARIABLE)
        if(DEFINED "${_GTEH_CUSTOM_CONTENT_FROM_VARIABLE}")
            set(CUSTOM_CONTENT "${${_GTEH_CUSTOM_CONTENT_FROM_VARIABLE}}")
        else()
            set(CUSTOM_CONTENT "")
        endif()
    endif()

    get_filename_component(_GENERATE_EXPORT_HEADER_MODULE_DIR
            "${CMAKE_CURRENT_LIST_FILE}" PATH)

    set("${TARGET_LIBRARY}_GEN_EXPORT_HEADER_FILE" "${EXPORT_FILE_NAME}" PARENT_SCOPE)

    configure_file("${_GTEH_FILE_DIR}/exportheader.cmake.in"
            "${EXPORT_FILE_NAME}" @ONLY)
endfunction()

