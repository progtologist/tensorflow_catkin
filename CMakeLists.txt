cmake_minimum_required(VERSION 3.5.0)
project(tensorflow_catkin)

find_package(catkin_simple REQUIRED)
catkin_simple()

set(USE_GPU OFF CACHE BOOL "Build Tensorflow with GPU support")
set(CUDA_ROOT $ENV{CUDA_ROOT} CACHE PATH "CUDA root directory")
set(CUDNN_ROOT $ENV{CUDNN_ROOT} CACHE PATH "CUDNN root directory")
set(NCCL_ROOT $ENV{NCCL_ROOT} CACHE PATH "NCCL root directory")
set(NUM_MAKE_JOBS "" CACHE STRING "Number of jobs concurrently run during the build (passed as make -j parameter)")
set(CUDA_VERSION $ENV{CUDA_VERSION} CACHE STRING "CUDA version")
set(CUDNN_VERSION $ENV{CUDNN_VERSION} CACHE STRING "CUDNN version")

set(tensorflow_args 
    -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX=${CATKIN_DEVEL_PREFIX}
    # General TF options
    -Dtensorflow_BUILD_SHARED_LIB=ON
    -Dtensorflow_BUILD_ALL_KERNELS=ON
    -Dtensorflow_BUILD_CONTRIB_KERNELS=ON
    -Dtensorflow_ENABLE_GRPC_SUPPORT=OFF
    -Dtensorflow_ENABLE_SSL_SUPPORT=OFF
    -Dtensorflow_BUILD_CC_TESTS=OFF
    -Dtensorflow_BUILD_CC_EXAMPLE=OFF
    -Dtensorflow_BUILD_PYTHON_BINDINGS=OFF
    -Dtensorflow_BUILD_PYTHON_TESTS=OFF
    -Dtensorflow_OPTIMIZE_FOR_NATIVE_ARCH=OFF
    # GPU-specific options
    -Dtensorflow_ENABLE_GPU=${USE_GPU}
    -Dtensorflow_PATH_STATIC_LIB=${CUDA_ROOT}/lib64
    -Dtensorflow_CUDA_LIBRARY_PATH=${CUDA_ROOT}/lib64
    -DCUDA_CUDA_LIBRARY=${CUDA_ROOT}/lib64/stubs/libcuda.so
    -Dtensorflow_PATH_NCCL_STATIC_LIB=${NCCL_ROOT}/lib
    -Dtensorflow_CUDNN_INCLUDE=${CUDNN_ROOT}/include
    -Dtensorflow_PATH_CUDNN_STATIC_LIB=${CUDNN_ROOT}/lib64
    -Dtensorflow_CUDA_VERSION=${CUDA_VERSION}
    -Dtensorflow_CUDNN_VERSION=${CUDNN_VERSION}
  )

include(cmake/Modules/build_external_project_cmake.cmake)
build_external_project_cmake(tensorflow
  tensorflow/contrib/cmake
  https://github.com/tensorflow/tensorflow.git
  d2e24b6039433bd83478da8c8c2d6c58034be607
  "${tensorflow_args}")

add_library(tensorflow SHARED IMPORTED GLOBAL)
set_target_properties(tensorflow PROPERTIES 
  IMPORTED_LOCATION ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_LIB_DESTINATION}/libtensorflow${CMAKE_SHARED_LIBRARY_SUFFIX})
install(FILES ${CATKIN_DEVEL_PREFIX}/${CATKIN_PACKAGE_LIB_DESTINATION}/libtensorflow${CMAKE_SHARED_LIBRARY_SUFFIX}
              DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION})
install(DIRECTORY 
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/Eigen  
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/external
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/google
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/tensorflow
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/third_party
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_INCLUDE_DESTINATION}/unsupported
  DESTINATION ${CATKIN_GLOBAL_INCLUDE_DESTINATION})
install(FILES 
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_BIN_DESTINATION}/benchmark_model
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_BIN_DESTINATION}/compare_graphs
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_BIN_DESTINATION}/summarize_graph
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_BIN_DESTINATION}/transform_graph
  DESTINATION ${CATKIN_GLOBAL_BIN_DESTINATION})
install(FILES
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_LIB_DESTINATION}/cmake/TensorflowConfig.cmake
  ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_LIB_DESTINATION}/cmake/TensorflowConfig-release.cmake
  DESTINATION ${CATKIN_GLOBAL_SHARE_DESTINATION}/Tensorflow/cmake)

cs_add_library(${PROJECT_NAME} src/dependency_tracker.cc)
add_dependencies(${PROJECT_NAME} tensorflow_src)
target_link_libraries(${PROJECT_NAME} tensorflow)

cs_install()

cs_export(
  INCLUDE_DIRS ${CATKIN_DEVEL_PREFIX}/include
CFG_EXTRAS tensorflow-extras.cmake)
