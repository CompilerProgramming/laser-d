#
# foundation static library
#

# All C sources in this directory make up the library. Objective-C sources are
# added on Apple platforms only.
file(GLOB FOUNDATION_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.c")
file(GLOB FOUNDATION_HEADERS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.h")

if(APPLE)
  file(GLOB FOUNDATION_OBJC_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.m")
  list(APPEND FOUNDATION_SOURCES ${FOUNDATION_OBJC_SOURCES})
endif()

#-----------------------------------------------------------------------------
# Generated version.c
#-----------------------------------------------------------------------------
set(FOUNDATION_VERSION_FILE ${CMAKE_CURRENT_BINARY_DIR}/version.c)

add_custom_command(
  OUTPUT ${FOUNDATION_VERSION_FILE}
  COMMAND ${CMAKE_COMMAND}
          -DLIBNAME=foundation
          -DOUTPUT=${FOUNDATION_VERSION_FILE}
          -DSOURCE_DIR=${PROJECT_SOURCE_DIR}
          -P ${PROJECT_SOURCE_DIR}/cmake/generate_version.cmake
  COMMENT "Generating foundation version.c"
  VERBATIM)

# Ensure version.c exists before the first build (the custom command keeps it
# current on subsequent builds).
if(NOT EXISTS ${FOUNDATION_VERSION_FILE})
  execute_process(COMMAND ${CMAKE_COMMAND}
                  -DLIBNAME=foundation
                  -DOUTPUT=${FOUNDATION_VERSION_FILE}
                  -DSOURCE_DIR=${PROJECT_SOURCE_DIR}
                  -P ${PROJECT_SOURCE_DIR}/cmake/generate_version.cmake)
endif()

#-----------------------------------------------------------------------------
# Library target
#-----------------------------------------------------------------------------
add_library(foundation STATIC ${FOUNDATION_SOURCES} ${FOUNDATION_VERSION_FILE} ${FOUNDATION_HEADERS})
add_library(foundation::foundation ALIAS foundation)

# foundation_flags is PUBLIC so consumers (tools, tests) inherit the include
# root, the FOUNDATION_COMPILE define and the platform defines.
target_link_libraries(foundation PUBLIC foundation_flags)

#-----------------------------------------------------------------------------
# System libraries / frameworks
#-----------------------------------------------------------------------------
if(WIN32)
  target_link_libraries(foundation PUBLIC kernel32 user32 shell32 advapi32)
elseif(APPLE)
  target_link_libraries(foundation PUBLIC
    "-framework Cocoa"
    "-framework CoreFoundation"
    m)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  find_package(Threads REQUIRED)
  target_link_libraries(foundation PUBLIC Threads::Threads ${CMAKE_DL_LIBS} m)
else()
  # Other UNIX-like platforms (BSD, etc.)
  find_package(Threads REQUIRED)
  target_link_libraries(foundation PUBLIC Threads::Threads ${CMAKE_DL_LIBS} m)
endif()
