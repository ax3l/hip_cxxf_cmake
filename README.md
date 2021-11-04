### C/C++/Fortran HIP Build (CMake)

Re issue in:
- https://github.com/ROCm-Developer-Tools/HIP/pull/2280
- original PR (stalled): https://github.com/ROCm-Developer-Tools/HIP/pull/2190
- original issues: https://github.com/ROCm-Developer-Tools/HIP/issues/2158 https://github.com/ROCm-Developer-Tools/HIP/issues/2275

Build with:
```
CXX=$(which clang++) FC=$(which gfortran) cmake -S . -B build
cmake --build build
```

The original error that you will see is:
```
gfortran: error: unrecognized command line option ‘-mllvm’
clang-12: warning: argument unused during compilation: '-amdgpu-function-calls=false' [-Wunused-command-line-argument]
gfortran: error: unrecognized command line option ‘-amdgpu-early-inline-all=true’
gfortran: error: unrecognized command line option ‘-amdgpu-function-calls=false’
gfortran: error: unrecognized command line option ‘--offload-arch=gfx900’; did you mean ‘--offload-abi=ilp32’?
gfortran: error: unrecognized command line option ‘--offload-arch=gfx906’; did you mean ‘--offload-abi=ilp32’?
gfortran: error: unrecognized command line option ‘--offload-arch=gfx908’; did you mean ‘--offload-abi=ilp32’?
```

... Should be fixed in ROCm 4.4+: https://github.com/ROCm-Developer-Tools/HIP/pull/2280#issuecomment-856138090
