#
# Generate <libname>/version.c from `git describe`, mirroring build/ninja/version.py.
#
# Invoked as a build step:
#   cmake -DLIBNAME=foundation -DOUTPUT=<path>/version.c
#         -DSOURCE_DIR=<repo root> -P generate_version.cmake
#
# The file is only rewritten when its content changes, so it does not trigger a
# needless rebuild on every invocation.
#

if(NOT DEFINED LIBNAME)
  message(FATAL_ERROR "generate_version.cmake: LIBNAME not set")
endif()
if(NOT DEFINED OUTPUT)
  message(FATAL_ERROR "generate_version.cmake: OUTPUT not set")
endif()
if(NOT DEFINED SOURCE_DIR)
  set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
endif()

# Defaults matching version.py when git information is unavailable.
set(version_major "0")
set(version_minor "0")
set(version_revision "1")
set(version_build "0")
set(version_scm "0")

find_program(GIT_EXECUTABLE NAMES git git.exe)
if(GIT_EXECUTABLE)
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --tags --long
    WORKING_DIRECTORY "${SOURCE_DIR}"
    OUTPUT_VARIABLE git_describe
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
    RESULT_VARIABLE git_result)

  if(git_result EQUAL 0 AND git_describe)
    # Parse the commit count and hash from the right so tags may contain
    # prerelease suffixes such as v2.113.0-beta.1.
    if(git_describe MATCHES "^(.*)-([0-9]+)-g([0-9a-fA-F]+)$")
      set(version_tag "${CMAKE_MATCH_1}")
      set(version_build "${CMAKE_MATCH_2}")
      set(version_scm "${CMAKE_MATCH_3}")
      # version_t stores the source-control identifier in 32 bits even when
      # the repository configures git to emit a longer abbreviation.
      string(SUBSTRING "${version_scm}" 0 8 version_scm)

      # Use the first three numeric components of the tag and ignore a
      # conventional leading 'v' and any prerelease suffix.
      if(version_tag MATCHES "^v?([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(version_major "${CMAKE_MATCH_1}")
        set(version_minor "${CMAKE_MATCH_2}")
        set(version_revision "${CMAKE_MATCH_3}")
      endif()
    endif()
  endif()
endif()

if("${LIBNAME}" STREQUAL "foundation")
  set(module "")
else()
  set(module "_module")
endif()

set(generated
"/* ****** AUTOMATICALLY GENERATED, DO NOT EDIT ******
   This file is generated from the git describe command.
   Run the configure step to regenerate this file */

#include <foundation/version.h>
#include <${LIBNAME}/${LIBNAME}.h>

version_t
${LIBNAME}${module}_version(void) {
	return version_make(${version_major}, ${version_minor}, ${version_revision}, ${version_build}, 0x${version_scm});
}
")

set(previous "")
if(EXISTS "${OUTPUT}")
  file(READ "${OUTPUT}" previous)
endif()

if(NOT previous STREQUAL generated)
  file(WRITE "${OUTPUT}" "${generated}")
  message(STATUS "Generated ${OUTPUT} (version ${version_major}.${version_minor}.${version_revision}.${version_build})")
endif()
