# This function is used to force a build on a dependant project at cmake configuration phase.
# 
function(build_external_project_cmake target source_subdir url tag args) #FOLLOWING ARGUMENTS are the CMAKE_ARGS of ExternalProject_Add

    set(trigger_build_dir ${CMAKE_BINARY_DIR}/force_${target})

    #mktemp dir in build tree
    file(MAKE_DIRECTORY ${CATKIN_DEVEL_PREFIX}/include)
    string(REPLACE ";" " " arguments_string "${args}")

    #generate false dependency project
    set(CMAKE_LIST_CONTENT "
    cmake_minimum_required(VERSION 2.8)

    if(${CMAKE_VERSION} VERSION_LESS "3.7.0")
       # ExternalProject_Add doesn't know the option SOURCE_SUBDIR in CMake before 3.7
       file(DOWNLOAD \"https://raw.githubusercontent.com/Kitware/CMake/v3.8.0/Modules/ExternalProject.cmake\" ${trigger_build_dir}/ExternalProject.cmake)
       include(${trigger_build_dir}/ExternalProject.cmake)
    else()
        include(ExternalProject)
    endif()

    include(ProcessorCount)
    ProcessorCount(CORES)

    include(ExternalProject)
    ExternalProject_add(${target}
            GIT_REPOSITORY ${url}
            GIT_TAG ${tag}
            PATCH_COMMAND bash -c \"for i in ${PROJECT_SOURCE_DIR}/patches/*.patch\$<SEMICOLON> do git apply -p1 $i\$<SEMICOLON> done\"
            UPDATE_COMMAND \"\"
            BUILD_COMMAND make -j\${CORES} install
            INSTALL_COMMAND echo \"Install\"
            SOURCE_DIR ${target}_src
            SOURCE_SUBDIR ${source_subdir}
            BINARY_DIR ${target}_build
            CMAKE_ARGS ${arguments_string}
            )

            add_custom_target(trigger_${target})
            add_dependencies(trigger_${target} ${target})")

    file(WRITE ${trigger_build_dir}/CMakeLists.txt "${CMAKE_LIST_CONTENT}")

    file(MAKE_DIRECTORY ${trigger_build_dir}/build)

    execute_process(COMMAND ${CMAKE_COMMAND} ..
        WORKING_DIRECTORY ${trigger_build_dir}/build
        )
    execute_process(COMMAND ${CMAKE_COMMAND} --build . -- -j4
        WORKING_DIRECTORY ${trigger_build_dir}/build
        )
    set(${target}_DIR ${CATKIN_DEVEL_PREFIX} PARENT_SCOPE)

endfunction()