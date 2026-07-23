cmake_minimum_required(VERSION 3.24)

project(LaserDChecksumExample LANGUAGES C)

include(CTest)

get_filename_component(LASERD_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../.." ABSOLUTE)

if(WIN32)
    set(LASERD_COMPILER "${LASERD_ROOT}/bin/laserd.exe")
else()
    set(LASERD_COMPILER "${LASERD_ROOT}/bin/laserd")
endif()

list(APPEND CMAKE_MODULE_PATH "${LASERD_ROOT}/share/laserd/cmake")
include(LaserD)

add_library(laserd_checksum_example STATIC c/checksum.c)
target_include_directories(laserd_checksum_example PUBLIC c)
set_target_properties(laserd_checksum_example PROPERTIES
    OUTPUT_NAME laserd_checksum
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

laserd_add_executable(checksum_example
    SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/test/checksum_test.d"
    IMPORT_DIRECTORIES
        "${LASERD_ROOT}/import"
        "${CMAKE_CURRENT_SOURCE_DIR}/import"
    LINK_LIBRARIES laserd_checksum_example)

add_test(NAME checksum_example COMMAND "${checksum_example_EXECUTABLE}")
