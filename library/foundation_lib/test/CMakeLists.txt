#
# Foundation unit tests
#
# The test case sources include <test/test.h>, which resolves relative to the
# `test` directory being on the include path (in addition to the repository root
# supplied by foundation_flags for <foundation/...>).
#

#-----------------------------------------------------------------------------
# Test support libraries
#-----------------------------------------------------------------------------
set(TEST_LIB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/test/test.c)
if(APPLE)
  list(APPEND TEST_LIB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/test/test.m)
endif()

add_library(foundation_test STATIC ${TEST_LIB_SOURCES})
target_include_directories(foundation_test PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(foundation_test PRIVATE TEST_COMPILE=1)
target_link_libraries(foundation_test PUBLIC foundation)

add_library(foundation_mock STATIC ${CMAKE_CURRENT_SOURCE_DIR}/mock/mock.c)
target_include_directories(foundation_mock PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(foundation_mock PRIVATE TEST_COMPILE=1)
target_link_libraries(foundation_mock PUBLIC foundation)

#-----------------------------------------------------------------------------
# Discover test cases (each subdirectory with a main.c, except the aggregate
# launcher in `all`, which is only used for the monolithic build).
#-----------------------------------------------------------------------------
file(GLOB _test_mains CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*/main.c")
set(TEST_CASES "")
foreach(_main ${_test_mains})
  get_filename_component(_dir ${_main} DIRECTORY)
  get_filename_component(_name ${_dir} NAME)
  if(NOT _name STREQUAL "all")
    list(APPEND TEST_CASES ${_name})
  endif()
endforeach()
list(SORT TEST_CASES)

if(FOUNDATION_BUILD_MONOLITHIC)
  #---------------------------------------------------------------------------
  # Single binary combining every test case (BUILD_MONOLITHIC), driven by the
  # launcher in test/all/main.c.
  #---------------------------------------------------------------------------
  set(_mono_sources ${CMAKE_CURRENT_SOURCE_DIR}/all/main.c)
  foreach(_case ${TEST_CASES})
    list(APPEND _mono_sources ${CMAKE_CURRENT_SOURCE_DIR}/${_case}/main.c)
  endforeach()

  add_executable(test-all ${_mono_sources})
  target_link_libraries(test-all PRIVATE foundation_test foundation_mock foundation)

  add_test(NAME test-all
           COMMAND test-all
           WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
  set_tests_properties(test-all PROPERTIES TIMEOUT 600)
else()
  #---------------------------------------------------------------------------
  # One binary per test case, each registered with CTest.
  #---------------------------------------------------------------------------
  foreach(_case ${TEST_CASES})
    add_executable(test-${_case} ${CMAKE_CURRENT_SOURCE_DIR}/${_case}/main.c)
    target_link_libraries(test-${_case} PRIVATE foundation_test foundation_mock foundation)

    add_test(NAME test-${_case}
             COMMAND test-${_case}
             WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
    set_tests_properties(test-${_case} PROPERTIES TIMEOUT 300)
  endforeach()
endif()
