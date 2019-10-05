#!/bin/bash
# $PYTHON setup.py

set -e

step() {
    printf "\e[1m${*}\e[0m\n"
}
if [[ -z "$PYTHON" ]]; then
    export PYTHON=$(which python3)
fi
step "Generating build files"
( cd tbxtools && pwd && $PYTHON setup.py develop; )
pwd
tbx2cmake modules
[[ -f modules/CMakeLists.txt ]] || ( cd modules && ln -s cmake/CMakeLists.txt .; )
# While we have a simple non-resolving cmakelist disable things
# fast_linalg depends on lapack and isn't built by default
sed -ie 's;add_subdirectory(cctbx_project/fast_linalg);#add_subdirectory(cctbx_project/fast_linalg);' modules/autogen_CMakeLists.txt
# lstbx benchmark depends on fast_linalg in some undeclared way
sed -ie 's;add_subdirectory(benchmarks);#add_subdirectory(benchmarks);' modules/cctbx_project/scitbx/lstbx/CMakeLists.txt

step "Generating Build"
[[ -f "_build/build.ninja" ]] || (
    mkdir -p _build && cd _build
    # Extra python args to ensure picks up conda python
    cmake ../modules -GNinja \
        -DBOOST_ROOT=$CONDA_PREFIX \
        -DPython_ROOT_DIR=$CONDA_PREFIX -DPython_FIND_STRATEGY=LOCATION
)

step "Build"
(
    cd _build
    # Dependency resolution isn't completely derived so do generation first
    ninja scitbx_refresh
    ninja
)

# step ""
