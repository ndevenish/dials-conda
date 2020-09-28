#!/bin/bash
# $PYTHON setup.py

set -e

# Flag for debugging the build - will try to softlink instead of final install
if [[ -z $CONDA_BUILD_STATE ]]; then
    export INSTALL_DEVELOP=1
    echo "RUNNING IN DEVELOP MODE"
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

export CC="ccache gcc"
export CXX="ccache g++"
# Set max cache size so we don't carry old objects for too long
#ccache -M 2G

echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"


export CCACHE_BASEDIR="$(cd ${SRC_DIR}/.. && pwd)"

export CCACHE_LOGFILE="${SRC_DIR}/cache.debug"

printf "Environment:\e[37m\n"
env | sort
printf "\e[0m-------DONE------"


echo "PATH Python: $(which python)"
#${PYTHON}"
echo "Host Python: $PYTHON"

#set -x
#if [[ -z "$PYTHON" ]]; then
#    export PYTHON=$(which python3)
#fi
#if [[ ! -f "$PYTHON" ]]; then
#    export PYTHON=$(which python3) 
#   echo 'Conda environment error? No python at $PYTHON. Using PATH: ' ${PYTHON}
#    exit 1
#fi

#export BUILD_PYTHON=
#exit 0
stage "Generating CMake build files from SConscripts"
python -mpip install tbxtools/
pwd
tbx2cmake modules
step "Create CMakeLists"
[[ -f modules/CMakeLists.txt ]] || ( cd modules && ln -s cmake/CMakeLists.txt .; )
poststep
# Replace libtbx.env loading with one that works via entrypoints
# step "Replace libtbx environment"
# cp patches/env_generic.py modules/cctbx_project/libtbx/load_env.py
# poststep

stage "Generating Build"

ccache -z

[[ -f "_build/build.ninja" ]] || (
    mkdir -p _build && cd _build
    # Extra python args to ensure picks up conda python
    cmake ../modules -GNinja \
        -DBOOST_ROOT=$CONDA_PREFIX \
        -DPython_ROOT_DIR=$PREFIX -DPython_FIND_STRATEGY=LOCATION \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DCMAKE_PREFIX_PATH=$CONDA_PREFIX
)

stage "Build"
(
    cd _build
    # Dependency resolution seems to have some bugs
    ninja scitbx_refresh
    # Next not needed, but for diagnosing problem do first
    ninja dxtbx_refresh
    # Ahhh screw it - found spotfinder_array_family_flex_ext also needs cctbx
    ninja refresh_meta
    ninja
)

ccache -s

stage "Install"
export LIBTBX_BUILD=$(pwd)/_build

(

    mkdir -p modules_setup
    cd modules_setup

    ln -fs $(ls -d ../modules/*/ | grep -v cmake | grep -v cctbx_project) .
    ln -fs $(ls -d ../modules/cctbx_project/*/ | grep -v dxtbx) .
    ln -fs ../modules/cmake/setup.py.template setup.py

    mkdir pycbf && cp ../_build/lib/pycbf.py pycbf/__init__.py
    # Make sure ccp4io included in this
    touch ccp4io/__init__.py ccp4io/libccp4/__init__.py ccp4io/libccp4/data/__init__.py
    touch dials/templates/__init__.py

    pwd

    $PYTHON setup.py install
#--no-deps --ignore-installed -vvv

#--no-deps --ignore-installed -vvv
)

(
    cd _build
    ninja install
)

