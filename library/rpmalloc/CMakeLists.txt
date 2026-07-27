add_library(laserd_rpmalloc STATIC
    rpmalloc/rpmalloc.c)
add_library(LaserD::rpmalloc ALIAS laserd_rpmalloc)

target_compile_features(laserd_rpmalloc PRIVATE c_std_11)
target_compile_definitions(laserd_rpmalloc
    PRIVATE
        ENABLE_OVERRIDE=0
        RPMALLOC_FIRST_CLASS_HEAPS=1)
if(MSVC)
    target_compile_options(laserd_rpmalloc
        PRIVATE /experimental:c11atomics)
endif()
target_include_directories(laserd_rpmalloc
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/rpmalloc>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/laserd/rpmalloc>")

set_target_properties(laserd_rpmalloc PROPERTIES
    OUTPUT_NAME laserd_rpmalloc
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

if(WIN32)
    target_link_libraries(laserd_rpmalloc PUBLIC Advapi32)
endif()

install(TARGETS laserd_rpmalloc
    EXPORT LaserDTargets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES rpmalloc/rpmalloc.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/laserd/rpmalloc")
install(DIRECTORY laserd/
    DESTINATION import/laserd
    FILES_MATCHING
        PATTERN "*.d"
        PATTERN "c" EXCLUDE)
install(FILES LICENSE
    DESTINATION share/laserd/licenses/rpmalloc)
