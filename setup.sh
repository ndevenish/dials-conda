#!/bin/bash

set -e

mkdir -p modules_setup
cd modules_setup

ln -fs $(ls -d ../modules/*/ | grep -v cmake | grep -v cctbx_project) .
ln -fs $(ls -d ../modules/cctbx_project/*/ | grep -v dxtbx) .
ln -fs ../setup.py

