add_library(laserd_utf8proc STATIC utf8proc.c)
add_library(LaserD::utf8proc ALIAS laserd_utf8proc)

target_compile_features(laserd_utf8proc PRIVATE c_std_11)
target_compile_definitions(laserd_utf8proc PUBLIC UTF8PROC_STATIC)
target_include_directories(laserd_utf8proc
    PUBLIC
        "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>"
        "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/laserd/utf8proc>")
set_target_properties(laserd_utf8proc PROPERTIES
    OUTPUT_NAME laserd_utf8proc
    POSITION_INDEPENDENT_CODE ON
    MSVC_RUNTIME_LIBRARY MultiThreaded)

install(TARGETS laserd_utf8proc
    EXPORT LaserDTargets
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(FILES utf8proc.h
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/laserd/utf8proc")
install(FILES LICENSE.md
    DESTINATION share/laserd/licenses/utf8proc)
