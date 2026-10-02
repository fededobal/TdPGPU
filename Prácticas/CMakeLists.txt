cmake_minimum_required(VERSION 3.20)
project(practicas CXX)

set(CMAKE_CXX_STANDARD 17)

# Headers de CUDA traídos del cluster, solo para que el editor entienda el código
include_directories(/Users/fededobal/cuda-headers/include)

# __CUDACC__ hace que los headers expongan las extensiones de nvcc
add_compile_definitions(__CUDACC__)

# Un "target" ficticio por archivo: nunca se compila acá, solo sirve
# para que CLion sepa qué flags aplicar a cada .cu
file(GLOB_RECURSE FUENTES "*.cu")
add_library(indexado OBJECT EXCLUDE_FROM_ALL ${FUENTES})
set_source_files_properties(${FUENTES} PROPERTIES LANGUAGE CXX)