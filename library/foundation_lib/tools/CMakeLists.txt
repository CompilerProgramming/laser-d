#
# Foundation command line tools
#

set(FOUNDATION_TOOLS bin2hex hashify uuidgen)

foreach(tool ${FOUNDATION_TOOLS})
  add_executable(${tool} ${CMAKE_CURRENT_SOURCE_DIR}/${tool}/main.c)
  # Tool-local headers such as errorcodes.h live next to main.c.
  target_include_directories(${tool} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/${tool})
  target_link_libraries(${tool} PRIVATE foundation)
  set_target_properties(${tool} PROPERTIES OUTPUT_NAME ${tool})
endforeach()
