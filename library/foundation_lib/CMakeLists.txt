#
# Unified CMake build for the Foundation library
#
# Public Domain - see LICENSE
#
# This build replaces the platform-specific Ninja/MSVC/Xcode project files with a
# single CMake definition that works on Linux, Windows and macOS. It builds the
# foundation static library, the command line tools (bin2hex, hashify, uuidgen)
# and the unit tests (registered with CTest).
#

cmake_minimum_required(VERSION 3.16)

project(foundation
        VERSION 1.0.0
        DESCRIPTION "Cross-platform foundation library in C11"
        HOMEPAGE_URL "https://github.com/mjansson/foundation_lib"
        LANGUAGES C)

# Objective-C sources are only compiled on Apple platforms.
if(APPLE)
  enable_language(OBJC)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

#-----------------------------------------------------------------------------
# Options
#-----------------------------------------------------------------------------
option(FOUNDATION_BUILD_TOOLS "Build the foundation command line tools" ON)
option(FOUNDATION_BUILD_TESTS "Build the foundation unit tests" ON)
# Off by default: -Werror against unpinned "latest" CI compilers is fragile, as
# each new GCC/Clang/MSVC release can promote a fresh warning to a hard error
# (e.g. newer GCC flags the static forward declarations in math.h). Opt in with
# -DFOUNDATION_WARNINGS_AS_ERRORS=ON to get the strict upstream behavior.
option(FOUNDATION_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
option(FOUNDATION_BUILD_MONOLITHIC "Build a single test-all binary instead of one binary per test" OFF)

# Static library only, matching the upstream build. Shared library support in the
# foundation code requires BUILD_DYNAMIC_LINK plumbing that is out of scope here.
set(BUILD_SHARED_LIBS OFF)

#-----------------------------------------------------------------------------
# Default build type
#-----------------------------------------------------------------------------
# The foundation build.h header understands four build flavours which map onto
# the standard CMake configuration types as follows:
#
#   Debug          -> BUILD_DEBUG    (unoptimized, full asserts/logging/tracking)
#   Release        -> BUILD_RELEASE  (optimized, asserts/logging/tracking on)
#   RelWithDebInfo -> BUILD_PROFILE  (optimized, profiling enabled)
#   MinSizeRel     -> BUILD_DEPLOY   (optimized, all debug/profiling disabled)
#
get_property(_is_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(NOT _is_multi_config AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
               Debug Release RelWithDebInfo MinSizeRel)
endif()

#-----------------------------------------------------------------------------
# Common compile settings, carried to every target via an INTERFACE library
#-----------------------------------------------------------------------------
add_library(foundation_flags INTERFACE)

# The repository root is the include root so that <foundation/foundation.h> and
# <test/test.h> resolve everywhere.
target_include_directories(foundation_flags INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})

# FOUNDATION_COMPILE only toggles the extern "C" export decoration; for a static
# build it is harmless and the upstream build defines it globally.
target_compile_definitions(foundation_flags INTERFACE FOUNDATION_COMPILE=1)

# Map the CMake configuration onto the foundation BUILD_* flavour.
target_compile_definitions(foundation_flags INTERFACE
  $<$<CONFIG:Debug>:BUILD_DEBUG=1>
  $<$<CONFIG:Release>:BUILD_RELEASE=1>
  $<$<CONFIG:RelWithDebInfo>:BUILD_PROFILE=1>
  $<$<CONFIG:MinSizeRel>:BUILD_DEPLOY=1>)

if(FOUNDATION_BUILD_MONOLITHIC)
  target_compile_definitions(foundation_flags INTERFACE BUILD_MONOLITHIC=1)
endif()

if(MSVC)
  # Match the upstream MSVC flags. C11 atomics are still experimental in MSVC and
  # required by atomic.h.
  target_compile_definitions(foundation_flags INTERFACE _UNICODE UNICODE)
  target_compile_options(foundation_flags INTERFACE
    $<$<COMPILE_LANGUAGE:C>:/std:c17>
    $<$<COMPILE_LANGUAGE:C>:/experimental:c11atomics>
    # /Zi + /FS: emit debug info (PDBs) in every configuration, as the upstream
    # build does. Symbol resolution (stacktrace) depends on it. /FS serializes
    # concurrent PDB writes under the Ninja/parallel builds.
    /Zi /FS
    /Oi /Oy- /GS- /Gy- /Qpar- /fp:precise /fp:except-
    /Zc:forScope /Zc:wchar_t /openmp-)
  # Produce a PDB alongside every executable so stack traces resolve to symbols.
  target_link_options(foundation_flags INTERFACE /DEBUG)
  if(FOUNDATION_WARNINGS_AS_ERRORS)
    # /wd4201 : nameless struct/union, which is valid C11
    target_compile_options(foundation_flags INTERFACE /W4 /WX /wd4201)
  else()
    target_compile_options(foundation_flags INTERFACE /W4 /wd4201)
  endif()
else()
  # GCC / Clang. Note: fast/unsafe math is intentionally NOT enabled - the code
  # relies on isfinite() guards that -ffinite-math-only would optimize away.
  target_compile_options(foundation_flags INTERFACE
    $<$<COMPILE_LANGUAGE:C>:-std=c11>
    -fstrict-aliasing -fno-math-errno -fno-trapping-math
    # -funit-at-a-time is a GCC-only optimization flag; Clang rejects it and
    # (under -Werror) fails via -Wignored-optimization-argument.
    $<$<C_COMPILER_ID:GNU>:-funit-at-a-time>)
  if(FOUNDATION_WARNINGS_AS_ERRORS)
    target_compile_options(foundation_flags INTERFACE -Wall -Wextra -Werror)
  else()
    target_compile_options(foundation_flags INTERFACE -Wall -Wextra)
  endif()
endif()

# Platform specific defines and system libraries, exposed through the same
# interface target so tools and tests inherit them when linking foundation.
if(UNIX AND NOT APPLE)
  target_compile_definitions(foundation_flags INTERFACE _GNU_SOURCE=1)
endif()

if(APPLE)
  # Objective-C sources (delegate.m, fs.m, ...) use ARC constructs such as
  # __weak, so they must be compiled with ARC enabled, matching the upstream
  # build (clang.py: -fobjc-arc -fno-objc-exceptions).
  target_compile_options(foundation_flags INTERFACE
    $<$<COMPILE_LANGUAGE:OBJC>:-fobjc-arc>
    $<$<COMPILE_LANGUAGE:OBJC>:-fno-objc-exceptions>)
endif()

#-----------------------------------------------------------------------------
# Output directories
#-----------------------------------------------------------------------------
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

#-----------------------------------------------------------------------------
# Targets
#-----------------------------------------------------------------------------
add_subdirectory(foundation)

if(FOUNDATION_BUILD_TOOLS)
  add_subdirectory(tools)
endif()

if(FOUNDATION_BUILD_TESTS)
  enable_testing()
  add_subdirectory(test)
endif()
