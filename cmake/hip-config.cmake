
####### Expanded from @PACKAGE_INIT@ by configure_package_config_file() #######
####### Any changes to this file will be overwritten by the next CMake run ####
####### The input file was hip-config.cmake.in                            ########

#get_filename_component(PACKAGE_PREFIX_DIR "${CMAKE_CURRENT_LIST_DIR}/../../../" ABSOLUTE)
get_filename_component(PACKAGE_PREFIX_DIR "/sw/spock/spack-envs/views/rocm-4.1.0/hip/" ABSOLUTE)

macro(set_and_check _var _file)
  set(${_var} "${_file}")
  if(NOT EXISTS "${_file}")
    message(FATAL_ERROR "File or directory ${_file} referenced by variable ${_var} does not exist !")
  endif()
endmacro()

macro(check_required_components _NAME)
  foreach(comp ${${_NAME}_FIND_COMPONENTS})
    if(NOT ${_NAME}_${comp}_FOUND)
      if(${_NAME}_FIND_REQUIRED_${comp})
        set(${_NAME}_FOUND FALSE)
      endif()
    endif()
  endforeach()
endmacro()

####################################################################################
include(CheckCXXCompilerFlag)
include(CMakeFindDependencyMacro OPTIONAL RESULT_VARIABLE _CMakeFindDependencyMacro_FOUND)
if (NOT _CMakeFindDependencyMacro_FOUND)
  macro(find_dependency dep)
    if (NOT ${dep}_FOUND)
      set(cmake_fd_version)
      if (${ARGC} GREATER 1)
        set(cmake_fd_version ${ARGV1})
      endif()
      set(cmake_fd_exact_arg)
      if(${CMAKE_FIND_PACKAGE_NAME}_FIND_VERSION_EXACT)
        set(cmake_fd_exact_arg EXACT)
      endif()
      set(cmake_fd_quiet_arg)
      if(${CMAKE_FIND_PACKAGE_NAME}_FIND_QUIETLY)
        set(cmake_fd_quiet_arg QUIET)
      endif()
      set(cmake_fd_required_arg)
      if(${CMAKE_FIND_PACKAGE_NAME}_FIND_REQUIRED)
        set(cmake_fd_required_arg REQUIRED)
      endif()
      find_package(${dep} ${cmake_fd_version}
          ${cmake_fd_exact_arg}
          ${cmake_fd_quiet_arg}
          ${cmake_fd_required_arg}
      )
      string(TOUPPER ${dep} cmake_dep_upper)
      if (NOT ${dep}_FOUND AND NOT ${cmake_dep_upper}_FOUND)
        set(${CMAKE_FIND_PACKAGE_NAME}_NOT_FOUND_MESSAGE "${CMAKE_FIND_PACKAGE_NAME} could not be found because dependency ${dep} could not be found.")
        set(${CMAKE_FIND_PACKAGE_NAME}_FOUND False)
        return()
      endif()
      set(cmake_fd_version)
      set(cmake_fd_required_arg)
      set(cmake_fd_quiet_arg)
      set(cmake_fd_exact_arg)
    endif()
  endmacro()
endif()

#Number of parallel jobs by default is 1
if(NOT DEFINED HIP_CLANG_NUM_PARALLEL_JOBS)
  set(HIP_CLANG_NUM_PARALLEL_JOBS 1)
endif()
set(HIP_COMPILER "clang")
set(HIP_RUNTIME "rocclr")

set_and_check( hip_INCLUDE_DIR "${PACKAGE_PREFIX_DIR}/include" )
set_and_check( hip_INCLUDE_DIRS "${hip_INCLUDE_DIR}" )
set_and_check( hip_LIB_INSTALL_DIR "${PACKAGE_PREFIX_DIR}/lib" )
set_and_check( hip_BIN_INSTALL_DIR "${PACKAGE_PREFIX_DIR}/bin" )

set_and_check(hip_HIPCC_EXECUTABLE "${hip_BIN_INSTALL_DIR}/hipcc")
set_and_check(hip_HIPCONFIG_EXECUTABLE "${hip_BIN_INSTALL_DIR}/hipconfig")

# set a default path for ROCM_PATH
if(NOT DEFINED ROCM_PATH)
  set(ROCM_PATH /opt/rocm)
endif()

#If HIP isnot installed under ROCm, need this to find HSA assuming HSA is under ROCm
if(DEFINED ENV{ROCM_PATH})
  set(ROCM_PATH "$ENV{ROCM_PATH}")
endif()

if(HIP_COMPILER STREQUAL "clang")
  set(HIP_CLANG_ROOT "${ROCM_PATH}/llvm")
  if(NOT HIP_CXX_COMPILER)
    set(HIP_CXX_COMPILER ${CMAKE_CXX_COMPILER})
  endif()
  if(HIP_CXX_COMPILER MATCHES ".*hipcc")
    execute_process(COMMAND ${HIP_CXX_COMPILER} --version
                    OUTPUT_STRIP_TRAILING_WHITESPACE
                    OUTPUT_VARIABLE HIP_CLANG_CXX_COMPILER_VERSION_OUTPUT)
    if(HIP_CLANG_CXX_COMPILER_VERSION_OUTPUT MATCHES "InstalledDir:[ \t]*([^\n]*)")
      get_filename_component(HIP_CLANG_ROOT "${CMAKE_MATCH_1}" DIRECTORY)
    endif()
  elseif (HIP_CXX_COMPILER MATCHES ".*clang\\+\\+")
    get_filename_component(HIP_CLANG_ROOT "${HIP_CXX_COMPILER}" DIRECTORY)
    get_filename_component(HIP_CLANG_ROOT "${HIP_CLANG_ROOT}" DIRECTORY)
  endif()
  file(GLOB HIP_CLANG_INCLUDE_SEARCH_PATHS ${HIP_CLANG_ROOT}/lib/clang/*/include)
  find_path(HIP_CLANG_INCLUDE_PATH stddef.h
      HINTS
          ${HIP_CLANG_INCLUDE_SEARCH_PATHS}
      NO_DEFAULT_PATH)
  find_dependency(AMDDeviceLibs)
  set(AMDGPU_TARGETS "gfx900;gfx906;gfx908" CACHE STRING "AMD GPU targets to compile for")
  set(GPU_TARGETS "${AMDGPU_TARGETS}" CACHE STRING "GPU targets to compile for")
else()
  find_dependency(hcc)
endif()

find_dependency(amd_comgr)

#include( "${CMAKE_CURRENT_LIST_DIR}/hip-targets.cmake" )
include( "/sw/spock/spack-envs/views/rocm-4.1.0/hip/lib/cmake/hip/hip-targets.cmake" )

#Using find_dependecy to locate the dependency for the packagaes
#This makes the cmake generated file xxxx-targets to supply the linker libraries
# without worrying other transitive dependencies
find_dependency(hsa-runtime64)
find_dependency(Threads)
find_dependency(ROCclr)

#get_filename_component cannot resolve the symlinks if called from /opt/rocm/lib/hip
#and do three level up again
#get_filename_component(_DIR "${CMAKE_CURRENT_LIST_DIR}" REALPATH)
get_filename_component(_DIR "/sw/spock/spack-envs/views/rocm-4.1.0/hip/lib/cmake/hip/" REALPATH)
get_filename_component(_IMPORT_PREFIX "${_DIR}/../../../" REALPATH)

#if HSA is not under ROCm then provide CMAKE_PREFIX_PATH=<HSA_PATH>
find_path(HSA_HEADER hsa/hsa.h
  PATHS
    "${_IMPORT_PREFIX}/../include"
    /opt/rocm/include
)

if (HSA_HEADER-NOTFOUND)
  message (FATAL_ERROR "HSA header not found! ROCM_PATH environment not set")
endif()

# Right now this is only supported for amd platforms
set_target_properties(hip::host PROPERTIES
  INTERFACE_COMPILE_DEFINITIONS "__HIP_PLATFORM_HCC__=1"
)

if(HIP_RUNTIME MATCHES "rocclr")
  set_target_properties(hip::amdhip64 PROPERTIES
    INTERFACE_COMPILE_DEFINITIONS "__HIP_ROCclr__=1"
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}"
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}"
  )
  set_target_properties(hip::device PROPERTIES
    INTERFACE_COMPILE_DEFINITIONS "__HIP_ROCclr__=1"
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/../include"
  )
else()
  set_target_properties(hip::hip_hcc_static PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}"
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}")

  set_target_properties(hip::hip_hcc PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}"
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include;${HSA_HEADER}"
  )

  get_target_property(amdhip64_type hip::amdhip64 TYPE)
  message(STATUS "hip::amdhip64 is ${amdhip64_type}")
  if(${amdhip64_type} STREQUAL "STATIC_LIBRARY")
    # For cyclic dependence
    target_link_libraries(amdrocclr_static INTERFACE hip::amdhip64)
  endif()

  set_target_properties(hip::device PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/include"
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_IMPORT_PREFIX}/../include"
  )
endif()

if(HIP_COMPILER STREQUAL "clang")
  if (HIP_CXX_COMPILER MATCHES ".*clang\\+\\+")
    set_property(TARGET hip::device APPEND PROPERTY
      INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:SHELL:-mllvm;-amdgpu-early-inline-all=true;-mllvm;-amdgpu-function-calls=false>"
    )
  endif()

  set_property(TARGET hip::device APPEND PROPERTY
      INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:SHELL:-x hip>"
    )
  if (NOT EXISTS ${AMD_DEVICE_LIBS_PREFIX}/amdgcn/bitcode)
    # This path is to support an older build of the device library
    # TODO: To be removed in the future.
    set_property(TARGET hip::device APPEND PROPERTY
      INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:--hip-device-lib-path=${AMD_DEVICE_LIBS_PREFIX}/lib>"
    )
  endif()

  set_property(TARGET hip::device APPEND PROPERTY
     INTERFACE_LINK_LIBRARIES "$<$<LINK_LANGUAGE:CXX>:--hip-link>"
  )

  set_property(TARGET hip::device APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${HIP_CLANG_INCLUDE_PATH}/.."
  )

  set_property(TARGET hip::device APPEND PROPERTY
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${HIP_CLANG_INCLUDE_PATH}/.."
  )

  foreach(GPU_TARGET ${GPU_TARGETS})
      set_property(TARGET hip::device APPEND PROPERTY
        INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:--cuda-gpu-arch=${GPU_TARGET}>"
      )
      set_property(TARGET hip::device APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES "$<$<LINK_LANGUAGE:CXX>:--cuda-gpu-arch=${GPU_TARGET}>"
      )
  endforeach()
  #Add support for parallel build and link
  if(${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
    check_cxx_compiler_flag("-parallel-jobs=1" HIP_CLANG_SUPPORTS_PARALLEL_JOBS)
  endif()
  if(HIP_CLANG_NUM_PARALLEL_JOBS GREATER 1)
    if(${HIP_CLANG_SUPPORTS_PARALLEL_JOBS} )
      set_property(TARGET hip::device APPEND PROPERTY
        INTERFACE_COMPILE_OPTIONS "$<$<COMPILE_LANGUAGE:CXX>:-parallel-jobs=${HIP_CLANG_NUM_PARALLEL_JOBS};-Wno-format-nonliteral>"
      )
      set_property(TARGET hip::device APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES "$<$<LINK_LANGUAGE:CXX>:-parallel-jobs=${HIP_CLANG_NUM_PARALLEL_JOBS}>"
      )
    else()
      message("clang compiler doesn't support parallel jobs")
    endif()
  endif()

  # Add support for __fp16 and _Float16, explicitly link with compiler-rt
  set_property(TARGET hip::host APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES "$<$<LINK_LANGUAGE:CXX>:${HIP_CLANG_INCLUDE_PATH}/../lib/linux/libclang_rt.builtins-x86_64.a>"
  )
  set_property(TARGET hip::device APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES "$<$<LINK_LANGUAGE:CXX>:${HIP_CLANG_INCLUDE_PATH}/../lib/linux/libclang_rt.builtins-x86_64.a>"
  )
endif()

set( hip_LIBRARIES hip::host hip::device)
set( hip_LIBRARY ${hip_LIBRARIES})

set(HIP_INCLUDE_DIR ${hip_INCLUDE_DIR})
set(HIP_INCLUDE_DIRS ${hip_INCLUDE_DIRS})
set(HIP_LIB_INSTALL_DIR ${hip_LIB_INSTALL_DIR})
set(HIP_BIN_INSTALL_DIR ${hip_BIN_INSTALL_DIR})
set(HIP_LIBRARIES ${hip_LIBRARIES})
set(HIP_LIBRARY ${hip_LIBRARY})
set(HIP_HIPCC_EXECUTABLE ${hip_HIPCC_EXECUTABLE})
set(HIP_HIPCONFIG_EXECUTABLE ${hip_HIPCONFIG_EXECUTABLE})
