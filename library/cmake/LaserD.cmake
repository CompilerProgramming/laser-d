include(CMakeParseArguments)

function(laserd_add_executable target)
    cmake_parse_arguments(LASERD
        ""
        ""
        "SOURCES;IMPORT_DIRECTORIES;LINK_LIBRARIES"
        ${ARGN})

    if(NOT LASERD_SOURCES)
        message(FATAL_ERROR
            "laserd_add_executable(${target}) requires SOURCES")
    endif()

    set(import_arguments)
    foreach(import_directory IN LISTS LASERD_IMPORT_DIRECTORIES)
        get_filename_component(import_directory
            "${import_directory}" ABSOLUTE)
        list(APPEND import_arguments "-I${import_directory}")
    endforeach()

    set(link_inputs)
    set(link_dependencies)
    foreach(library IN LISTS LASERD_LINK_LIBRARIES)
        if(TARGET "${library}")
            list(APPEND link_inputs "$<TARGET_FILE:${library}>")
            list(APPEND link_dependencies "${library}")
        else()
            list(APPEND link_inputs "${library}")
        endif()
    endforeach()

    set(platform_arguments)
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        list(APPEND platform_arguments -fPIC)
    endif()

    set(output "${CMAKE_CURRENT_BINARY_DIR}/${target}${CMAKE_EXECUTABLE_SUFFIX}")
    add_custom_command(
        OUTPUT "${output}"
        COMMAND "${LASERD_COMPILER}"
            -conf=
            -i
            ${platform_arguments}
            ${import_arguments}
            ${LASERD_SOURCES}
            ${link_inputs}
            "-of=${output}"
        DEPENDS
            "${LASERD_COMPILER}"
            ${LASERD_SOURCES}
            ${link_dependencies}
        COMMAND_EXPAND_LISTS
        VERBATIM)

    add_custom_target("${target}" ALL DEPENDS "${output}")
    set("${target}_EXECUTABLE" "${output}" PARENT_SCOPE)
endfunction()
