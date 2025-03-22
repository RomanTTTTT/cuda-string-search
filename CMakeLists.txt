cmake_minimum_required(VERSION 3.29)
project(cuda_string_search)

set(CMAKE_CXX_STANDARD 14)

add_executable(cuda_string_search
    alg.cpp cuda_reduce.cu)
