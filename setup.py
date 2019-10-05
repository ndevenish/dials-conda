from setuptools import setup, find_packages
import subprocess
import os
import json

# Get the version from git, for now
DIALS_VERSION = subprocess.check_output(["git", "describe"], cwd="dials").decode("utf-8").strip()
if DIALS_VERSION.startswith("v"):
    DIALS_VERSION = DIALS_VERSION[1:]


assert "LIBTBX_BUILD" in os.environ, "Need build to find modules list"
with open(os.path.join(os.environ["LIBTBX_BUILD"], "libtbx_env.json")) as f:
    env = json.load(f)
assert env

modules_entry_points = {"libtbx.module": [f"{module} = {module}" for module in env.keys()]}

print("Entry points: ", modules_entry_points)

setup(
    name="dials",
    version=DIALS_VERSION,
    classifiers=[
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: BSD License',
        'Operating System :: MacOS',
        'Operating System :: Microsoft :: Windows',
        'Operating System :: POSIX :: Linux',
    ],
    description="Diffraction Integration for Advanced Light Sources",
    author="Diamond Light Source",
    author_email="dials-support@lists.sourceforge.net",
    url="https://github.com/dials/dials",
    packages=find_packages(),
    # data_files=[
    #     (
    #         "dui/resources",
    #         [
    #             "src/dui/resources/DIALS_Logo_smaller_centred_grayed.png",
    #         ],
    #     )
    # ],
    # include_package_data=True,
    # entry_points={"console_scripts": ["dui=dui.main_dui:main"]},
    entry_points=modules_entry_points,
)

