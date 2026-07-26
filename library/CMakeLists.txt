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

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "Laser-D nsync requires a 64-bit target")
endif()
if(NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
    message(FATAL_ERROR "Laser-D nsync currently supports only x86-64")
endif()
if(NOT CMAKE_SYSTEM_NAME MATCHES "^(Windows|Linux|Darwin)$")
    message(FATAL_ERROR
        "Laser-D nsync supports only Windows, Linux, and macOS")
endif()

set(NSYNC_ENABLE_TESTS OFF CACHE BOOL "" FORCE)
set(NSYNC_ENABLE_CPP OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
add_subdirectory(nsync)
add_library(LaserD::nsync ALIAS nsync)

target_sources(nsync PRIVATE
    nsync_laserd/c/nsync_layout.c)
target_include_directories(nsync
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/nsync/public>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>")
if(UNIX)
    target_compile_options(nsync PRIVATE -pthread)
    target_link_libraries(nsync PUBLIC -pthread)
endif()
set_target_properties(nsync PROPERTIES
    OUTPUT_NAME laserd_nsync
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

install(FILES nsync/LICENSE
    DESTINATION share/laserd/licenses/nsync)

set(FOUNDATION_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(FOUNDATION_BUILD_TESTS OFF CACHE BOOL "" FORCE)
add_subdirectory(foundation_lib)
add_library(LaserD::foundation ALIAS foundation)

target_sources(foundation PRIVATE
    foundation/c/foundation_rpmalloc.c)
target_include_directories(foundation
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/foundation/c"
        "${CMAKE_CURRENT_SOURCE_DIR}/rpmalloc/rpmalloc")
target_link_libraries(foundation PUBLIC laserd_rpmalloc)

set_target_properties(foundation PROPERTIES
    OUTPUT_NAME laserd_foundation
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

install(TARGETS foundation
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES
    foundation_lib/foundation/base64.h
    foundation_lib/foundation/hash.h
    foundation_lib/foundation/pipe.h
    foundation_lib/foundation/process.h
    foundation_lib/foundation/stream.h
    foundation_lib/foundation/thread.h
    foundation_lib/foundation/types.h
    foundation_lib/foundation/platform.h
    foundation_lib/foundation/build.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/foundation")
install(FILES foundation/c/foundation_rpmalloc.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/laserd")
install(DIRECTORY foundation/import/
    DESTINATION import
    FILES_MATCHING PATTERN "*.d")
install(DIRECTORY import/
    DESTINATION import
    FILES_MATCHING PATTERN "*.d")

if(BUILD_TESTING)
    set(foundation_platform_libraries)
    if(WIN32)
        list(APPEND foundation_platform_libraries
            user32.lib
            shell32.lib
            advapi32.lib)
    elseif(APPLE)
        list(APPEND foundation_platform_libraries
            -L-framework
            -L-Cocoa
            -L-framework
            -L-CoreFoundation
            -L-lm)
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        list(APPEND foundation_platform_libraries
            -L-lpthread
            -L-ldl
            -L-lm)
    endif()

    laserd_add_executable(foundation_test
        SOURCES
            "${LASERD_REPOSITORY_ROOT}/compiler/test/laser-d/foundation_interface.d"
        IMPORT_DIRECTORIES
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/foundation/import"
            "${CMAKE_CURRENT_SOURCE_DIR}/import"
        LINK_LIBRARIES
            foundation
            laserd_rpmalloc
            ${foundation_platform_libraries})

    add_test(NAME foundation_interop
        COMMAND "${foundation_test_EXECUTABLE}")

    laserd_add_executable(foundation_process_pipe_test
        SOURCES
            "${LASERD_REPOSITORY_ROOT}/compiler/test/laser-d/foundation_process_pipe.d"
        IMPORT_DIRECTORIES
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/foundation/import"
            "${CMAKE_CURRENT_SOURCE_DIR}/import"
        LINK_LIBRARIES
            foundation
            laserd_rpmalloc
            ${foundation_platform_libraries})

    add_test(NAME foundation_process_pipe
        COMMAND "${foundation_process_pipe_test_EXECUTABLE}")

    laserd_add_executable(nsync_test
        SOURCES
            "${LASERD_REPOSITORY_ROOT}/compiler/test/laser-d/nsync_interface.d"
        IMPORT_DIRECTORIES
            "${CMAKE_SOURCE_DIR}"
            "${CMAKE_CURRENT_SOURCE_DIR}/foundation/import"
            "${CMAKE_CURRENT_SOURCE_DIR}/import"
        LINK_LIBRARIES
            foundation
            laserd_rpmalloc
            nsync
            ${foundation_platform_libraries})

    add_test(NAME nsync_interop
        COMMAND "${nsync_test_EXECUTABLE}")
endif()

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
