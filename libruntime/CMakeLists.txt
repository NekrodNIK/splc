cmake_minimum_required(VERSION 3.16)
project(splruntime C)

set(CMAKE_C_STANDARD 11)

add_library(splruntime STATIC spl_runtime.c)

# Export the include directory for downstream consumers
target_include_directories(splruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})