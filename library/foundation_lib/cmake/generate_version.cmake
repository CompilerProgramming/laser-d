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
    # Expected form: <major>.<minor>.<revision>-<build>-g<scm>
    string(REPLACE "-" ";" tokens "${git_describe}")
    list(LENGTH tokens token_count)
    if(token_count GREATER 2)
      list(GET tokens 0 version_numbers)
      list(GET tokens 1 version_build)
      list(GET tokens 2 version_scm_raw)
      # Drop the leading 'g' from the abbreviated commit hash.
      string(REGEX REPLACE "^g" "" version_scm "${version_scm_raw}")

      string(REPLACE "." ";" numbers "${version_numbers}")
      list(LENGTH numbers number_count)
      if(number_count GREATER 2)
        list(GET numbers 0 version_major)
        list(GET numbers 1 version_minor)
        list(GET numbers 2 version_revision)
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
