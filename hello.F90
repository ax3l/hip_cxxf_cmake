cmake_minimum_required(VERSION 3.15.0)
project(CXXF)

find_package(hip REQUIRED)

add_executable(vectoradd_cpp vectoradd.cxx)

target_compile_features(vectoradd_cpp PUBLIC cxx_std_14)
# work-around another bug:
# https://github.com/ROCm-Developer-Tools/HIP/issues/2278
set_property(TARGET vectoradd_cpp PROPERTY CXX_STANDARD 14)


target_link_libraries(vectoradd_cpp PUBLIC hip::device)       program hello
          print *, "Hello World!"
       end program
