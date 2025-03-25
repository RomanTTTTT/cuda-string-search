cmake_minimum_required(VERSION 3.22)
project(cuda_string_search)

set(CMAKE_CXX_STANDARD 14)

# Додаємо GoogleTest
set(GTEST_DIR third_party/googletest)
add_subdirectory(${GTEST_DIR})
include_directories(${GTEST_DIR}/googletest/include)

# Створюємо бібліотеку для AhoCorasick
add_library(AhoCorasickLib src/AhoCorasick.cpp)

# Створюємо виконуваний файл для тестів
add_executable(runTests tests/test.cpp)

# Лінкуємо бібліотеку AhoCorasick і GTest
target_link_libraries(runTests PRIVATE AhoCorasickLib gtest gtest_main pthread)
