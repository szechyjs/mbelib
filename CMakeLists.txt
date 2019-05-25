project(mbe)
cmake_minimum_required(VERSION 2.6)

if(MSVC)
    # needed for M_PI macro
    add_definitions(-D_USE_MATH_DEFINES)
endif()

FILE(GLOB SRCS *.c)

include_directories("${PROJECT_SOURCE_DIR}")

ADD_LIBRARY(mbe-static STATIC ${SRCS})
ADD_LIBRARY(mbe-shared SHARED ${SRCS})
if(NOT WIN32)
    TARGET_LINK_LIBRARIES(mbe-static m)
    TARGET_LINK_LIBRARIES(mbe-shared m)
endif()

include(GNUInstallDirs)

set_target_properties(mbe-static mbe-shared
                      PROPERTIES
                      OUTPUT_NAME mbe
                      VERSION 1.3
                      SOVERSION 1
                      INSTALL_NAME_DIR ${CMAKE_INSTALL_FULL_LIBDIR}
                      PUBLIC_HEADER "mbelib.h")

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/libmbe.pc.in"
               "${CMAKE_CURRENT_BINARY_DIR}/libmbe.pc"
               @ONLY)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/libmbe.pc"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")

install(TARGETS mbe-static mbe-shared
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

option(DISABLE_TEST "Disable building of test framework." OFF)

if (NOT DISABLE_TEST)
    enable_testing()
    add_subdirectory(test)
endif()
