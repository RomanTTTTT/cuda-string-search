cmake_minimum_required(VERSION 3.29)
project(cuda_string_search LANGUAGES CXX CUDA) # Додаємо підтримку CUDA

set(CMAKE_CXX_STANDARD 14)

# Додаємо GoogleTest
set(GTEST_DIR third_party/googletest)
add_subdirectory(${GTEST_DIR})
include_directories(${GTEST_DIR}/googletest/include)

# Створюємо бібліотеку для AhoCorasick
add_library(AhoCorasickLib src/AhoCorasick.cpp
        src/AhoCorasick.h
        src/AhoCorasick.h)

# Створюємо виконуваний файл для тестів
add_executable(runTests tests/test.cpp)

# Лінкуємо бібліотеку AhoCorasick і GTest
target_link_libraries(runTests PRIVATE AhoCorasickLib gtest gtest_main pthread)

# Створюємо окремий виконуваний файл cuda_reduce
add_executable(cuda_reduce cuda_reduce.cu)

add_executable(aho_corasick_cuda cuda/aho_corasick_cuda.cu)

# Встановлюємо необхідні прапори для компілятора NVCC
set_target_properties(cuda_reduce PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
