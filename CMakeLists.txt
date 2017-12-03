project(mbe)
cmake_minimum_required(VERSION 2.6)

FILE(GLOB SRCS *.c)

include_directories("${PROJECT_SOURCE_DIR}")

ADD_LIBRARY(mbe-static STATIC ${SRCS})
ADD_LIBRARY(mbe-shared SHARED ${SRCS})
TARGET_LINK_LIBRARIES(mbe-static m)
TARGET_LINK_LIBRARIES(mbe-shared m)

include(GNUInstallDirs)

set_target_properties(mbe-static mbe-shared
                      PROPERTIES
                      OUTPUT_NAME mbe
                      VERSION 1.0
                      SOVERSION 1
                      INSTALL_NAME_DIR ${CMAKE_INSTALL_FULL_LIBDIR}
                      PUBLIC_HEADER "mbelib.h")

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
