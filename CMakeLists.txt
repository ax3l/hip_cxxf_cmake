cmake_minimum_required(VERSION 3.15.0)
project(CXXF CXX Fortran)

find_package(hip REQUIRED)

add_executable(hello_f hello.F90)
add_executable(vectoradd_cpp vectoradd.cxx)

target_compile_features(vectoradd_cpp PUBLIC cxx_std_14)
# work-around another bug:
# https://github.com/ROCm-Developer-Tools/HIP/issues/2278
set_property(TARGET vectoradd_cpp PROPERTY CXX_STANDARD 14)


target_link_libraries(vectoradd_cpp PUBLIC hip::device)
# this is a simplified reproducer:
# assume that we actually build a
# C/C++-to-Fortran library binding and thus have to link `hip::device`
# publicly downstream (Fortran routine calls into C binding calls into
# C++ code that spawns HIP Kernels)
target_link_libraries(hello_f PUBLIC hip::device)  # this must be possible w/o failing gfortran
