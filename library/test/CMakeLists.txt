set(laserd_library_import_directories
    "${CMAKE_SOURCE_DIR}"
    "${CMAKE_SOURCE_DIR}/rpmalloc"
    "${CMAKE_SOURCE_DIR}/foundation_lib")

set(laserd_allocator_platform_libraries)
set(laserd_foundation_platform_libraries)
if(WIN32)
    list(APPEND laserd_allocator_platform_libraries advapi32.lib)
    list(APPEND laserd_foundation_platform_libraries
        user32.lib
        shell32.lib
        advapi32.lib)
elseif(APPLE)
    list(APPEND laserd_foundation_platform_libraries
        -L-framework
        -LCocoa
        -L-framework
        -LCoreFoundation
        -L-lm)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    list(APPEND laserd_foundation_platform_libraries
        -L-lpthread
        -L-ldl
        -L-lm)
endif()

laserd_add_executable(core_stdc_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/core_stdc.d"
    IMPORT_DIRECTORIES "${CMAKE_SOURCE_DIR}")
add_test(NAME core_stdc COMMAND "${core_stdc_test_EXECUTABLE}")

laserd_add_executable(traits_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/traits.d"
    IMPORT_DIRECTORIES "${CMAKE_SOURCE_DIR}")
add_test(NAME std_traits COMMAND "${traits_test_EXECUTABLE}")

laserd_add_executable(result_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/result.d"
    IMPORT_DIRECTORIES "${CMAKE_SOURCE_DIR}")
add_test(NAME result COMMAND "${result_test_EXECUTABLE}")

laserd_add_executable(rpmalloc_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/rpmalloc.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        laserd_rpmalloc
        ${laserd_allocator_platform_libraries})
add_test(NAME rpmalloc_c_interop COMMAND "${rpmalloc_test_EXECUTABLE}")

laserd_add_executable(memory_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/memory.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        laserd_rpmalloc
        ${laserd_allocator_platform_libraries})
add_test(NAME memory_facade COMMAND "${memory_test_EXECUTABLE}")

laserd_add_executable(hash_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/hash.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        laserd_rpmalloc
        ${laserd_allocator_platform_libraries})
add_test(NAME hash_table COMMAND "${hash_test_EXECUTABLE}")

laserd_add_executable(foundation_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/foundation.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        foundation
        laserd_rpmalloc
        ${laserd_foundation_platform_libraries})
add_test(NAME foundation_interop COMMAND "${foundation_test_EXECUTABLE}")

laserd_add_executable(process_pipe_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/process_pipe.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        foundation
        laserd_rpmalloc
        ${laserd_foundation_platform_libraries})
add_test(NAME foundation_process_pipe COMMAND "${process_pipe_test_EXECUTABLE}")

laserd_add_executable(thread_sync_test
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/thread_sync.d"
    IMPORT_DIRECTORIES ${laserd_library_import_directories}
    LINK_LIBRARIES
        foundation
        laserd_rpmalloc
        nsync
        ${laserd_foundation_platform_libraries})
add_test(NAME nsync_interop COMMAND "${thread_sync_test_EXECUTABLE}")
