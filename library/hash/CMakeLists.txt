install(DIRECTORY import/
    DESTINATION import
    FILES_MATCHING PATTERN "*.d")

if(BUILD_TESTING)
    set(hash_platform_libraries)
    if(WIN32)
        list(APPEND hash_platform_libraries advapi32.lib)
    endif()

    laserd_add_executable(hash_test
        SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test/hash_test.d"
        IMPORT_DIRECTORIES
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/import"
            "${CMAKE_SOURCE_DIR}/import"
        LINK_LIBRARIES
            laserd_rpmalloc
            ${hash_platform_libraries})

    add_test(NAME hash_table
        COMMAND "${hash_test_EXECUTABLE}")
endif()
