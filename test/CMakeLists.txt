project(mbetest)

add_subdirectory(gtest)
add_subdirectory(gmock)

FILE(GLOB SRCS *.cpp)

include_directories(
    ${PROJECT_SOURCE_DIR}/gtest/include
    ${PROJECT_SOURCE_DIR}/gmock/include
    ${mbe_SOURCE_DIR}
)

link_directories( ${mbe_BINARY_DIR} )

ADD_EXECUTABLE(mbetest ${SRCS})
TARGET_LINK_LIBRARIES(mbetest mbe gmock gtest)

add_test(gtest  mbetest)
