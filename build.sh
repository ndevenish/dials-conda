#!/bin/bash
# $PYTHON setup.py

set -e

# Flag for debugging the build - will try to softlink instead of final install
if [[ -z $CONDA_BUILD_STATE ]]; then
    export INSTALL_DEVELOP=1
fi

stage() {
    printf "\e[1m${*}\e[0m\n"
}
step() {
    printf "%-74s[" "$*"
    set +e
}
poststep() {
    if [[ $? -eq 0 ]]; then
        printf " \e[32mOK\e[0m ]\n"
        set -e
        return 0
    else
      printf "\e[31mFAIL\e[0m]\n"
        set -e
      return 1
    fi
}

if [[ -z "$PYTHON" ]]; then
    export PYTHON=$(which python3)
fi
if [[ ! -f "$PYTHON" ]]; then
    echo 'Conda environment error? No python at $PYTHON. Using PATH'
    export PYTHON=$(which python3)
fi

stage "Generating build files"
$PYTHON -mpip install tbxtools/
pwd
tbx2cmake modules
step "Create CMakeLists"
[[ -f modules/CMakeLists.txt ]] || ( cd modules && ln -s cmake/CMakeLists.txt .; )
poststep
# While we have a simple non-resolving cmakelist disable things
# fast_linalg depends on lapack and isn't built by default
step "Disable fast_linalg"
sed -ie 's;add_subdirectory(cctbx_project/fast_linalg);#add_subdirectory(cctbx_project/fast_linalg);' modules/autogen_CMakeLists.txt
poststep
# lstbx benchmark depends on fast_linalg in some undeclared way
step "Disable benchmarks"
sed -ie 's;add_subdirectory(benchmarks);#add_subdirectory(benchmarks);' modules/cctbx_project/scitbx/lstbx/CMakeLists.txt
poststep
# Replace libtbx.env loading with one that works via entrypoints
# step "Replace libtbx environment"
# cp patches/env_generic.py modules/cctbx_project/libtbx/load_env.py
# poststep

stage "Generating Build"
[[ -f "_build/build.ninja" ]] || (
    mkdir -p _build && cd _build
    # Extra python args to ensure picks up conda python
    cmake ../modules -GNinja \
        -DBOOST_ROOT=$CONDA_PREFIX \
        -DPython_ROOT_DIR=$CONDA_PREFIX -DPython_FIND_STRATEGY=LOCATION \
        -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX
)

stage "Build"
(
    cd _build
    # Dependency resolution isn't completely derived so do generation first
    ninja scitbx_refresh
    ninja
)

stage "Install"
export LIBTBX_BUILD=$(pwd)/_build

(

    mkdir -p modules_setup
    cd modules_setup

    ln -fs $(ls -d ../modules/*/ | grep -v cmake | grep -v cctbx_project) .
    ln -fs $(ls -d ../modules/cctbx_project/*/ | grep -v dxtbx) .
    ln -fs ../setup.py

    # Run the install
    if [[ -n "$INSTALL_DEVELOP" ]]; then
        $PYTHON -mpip install -e .
    else
        $PYTHON -mpip install .
    fi
)

(
    cd _build
    ninja install
)

