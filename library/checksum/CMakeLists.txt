add_library(laserd_checksum STATIC
    c/checksum.c)
add_library(LaserD::checksum ALIAS laserd_checksum)

target_include_directories(laserd_checksum
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/c>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/laserd>")

set_target_properties(laserd_checksum PROPERTIES
    OUTPUT_NAME laserd_checksum
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

install(TARGETS laserd_checksum
    EXPORT LaserDTargets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES c/checksum.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/laserd")
install(DIRECTORY import/
    DESTINATION import
    FILES_MATCHING PATTERN "*.d")

install(FILES example/CMakeLists.txt
    DESTINATION share/laserd/examples/checksum)
install(DIRECTORY c import test
    DESTINATION share/laserd/examples/checksum
    FILES_MATCHING
        PATTERN "*.c"
        PATTERN "*.h"
        PATTERN "*.d")

if(BUILD_TESTING)
    laserd_add_executable(checksum_test
        SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test/checksum_test.d"
        IMPORT_DIRECTORIES
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/import"
        LINK_LIBRARIES laserd_checksum)

    add_test(NAME checksum_c_interop
        COMMAND "${checksum_test_EXECUTABLE}")
endif()
