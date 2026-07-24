cmake_minimum_required(VERSION 3.24)

project(LaserDStandardLibrary LANGUAGES C)

include(CTest)
include(GNUInstallDirs)

get_filename_component(LASERD_REPOSITORY_ROOT
    "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)

set(LASERD_COMPILER "" CACHE FILEPATH
    "Path to the Dub-built laserd compiler")
if(NOT LASERD_COMPILER)
    message(FATAL_ERROR
        "Set LASERD_COMPILER to the Dub-built laserd executable")
endif()
get_filename_component(LASERD_COMPILER "${LASERD_COMPILER}" ABSOLUTE)
if(NOT EXISTS "${LASERD_COMPILER}")
    message(FATAL_ERROR "Laser-D compiler not found: ${LASERD_COMPILER}")
endif()

file(STRINGS "${LASERD_REPOSITORY_ROOT}/VERSION" LASERD_VERSION
    LIMIT_COUNT 1)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(LaserD)

add_subdirectory(checksum)
add_subdirectory(rpmalloc)
add_subdirectory(hash)

install(PROGRAMS "${LASERD_COMPILER}"
    TYPE BIN
    RENAME "laserd${CMAKE_EXECUTABLE_SUFFIX}")

if(WIN32)
    configure_file(cmake/sc.ini.in generated/sc.ini @ONLY)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/sc.ini" TYPE BIN)
else()
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(LASERD_PLATFORM_DFLAGS "-fPIC")
    else()
        set(LASERD_PLATFORM_DFLAGS "")
    endif()
    configure_file(cmake/dmd.conf.in generated/dmd.conf @ONLY)
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/generated/dmd.conf" TYPE BIN)
endif()

install(FILES object.d DESTINATION import)
install(DIRECTORY core DESTINATION import
    FILES_MATCHING PATTERN "*.d")

install(FILES
    "${LASERD_REPOSITORY_ROOT}/README.md"
    "${LASERD_REPOSITORY_ROOT}/LICENSE.txt"
    DESTINATION ".")
install(FILES README.md
    DESTINATION "."
    RENAME STANDARD_LIBRARY.md)
install(FILES cmake/LaserD.cmake
    DESTINATION share/laserd/cmake)

if(WIN32)
    set(LASERD_PACKAGE_PLATFORM windows)
elseif(APPLE)
    set(LASERD_PACKAGE_PLATFORM macos)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(LASERD_PACKAGE_PLATFORM linux)
else()
    message(FATAL_ERROR
        "Laser-D packages support Windows, Linux, and macOS")
endif()

set(CPACK_GENERATOR ZIP)
set(CPACK_PACKAGE_NAME laser-d)
set(CPACK_PACKAGE_VENDOR "Laser-D")
set(CPACK_PACKAGE_VERSION "${LASERD_VERSION}")
set(CPACK_PACKAGE_FILE_NAME
    "laser-d-${LASERD_VERSION}-${LASERD_PACKAGE_PLATFORM}-x86_64")
set(CPACK_PACKAGE_DIRECTORY "${LASERD_REPOSITORY_ROOT}/dist")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY ON)
include(CPack)
