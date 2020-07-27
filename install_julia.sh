#!/bin/bash

# This script allows for installing the Julia programming language runtime on
# OLCF systems.
#
# Authors: Jess Woods, Matt Belhorn
# 
#==============================================================================
# Notes for testing an installation:
# To use MPI/CUDA, put 'using mpi'/'using cuda' at the top of test julia script.
# Enter interactive job or batch script and use a jsrun command like:
#   ```
#   jsrun -n1 -g1 --smpiargs="-gpu" julia myprogram.jl
#   ```
# 
# TODO:
# - Allow version to be set on command line, only fallback to default
#   version if specific version is not specified.
# - Capture build logs for production installations.
# - Use verbose makefiles/builds.
# - Suitesparse build does not automatically find CUDA/CUBLAS.
# - Allow for updating an existing install if the MPI and CUDA packages
#   must be rebuilt.
#==============================================================================

# ----------------------
# Set user-modifiable parameters.

TARGET_HOST="${1:-test}"
VERSION="1.4.2"

# ----------------------
# Set fixed installation parameters.

# If a host was passed at the command line, use that to construct the prefix.
JULIA_ROOT="${1:+/sw/${TARGET_HOST}/julia}"
MODULE_ROOT="${1:+/sw/${TARGET_HOST}/modulefiles/core}"

# If above root strings are null, install in an ephemeral test prefix.
JULIA_ROOT="${JULIA_ROOT:-/tmp/${USER}/opt/julia}"
MODULE_ROOT="${MODULE_ROOT:-${JULIA_ROOT}/modulefiles/core}"

PREFIX="${JULIA_ROOT}/${VERSION}"
MODULE_NAME="julia/${VERSION}"
MODULE_FILE="${MODULE_ROOT}/${MODULE_NAME}.lua"

BUILD_DIR="/tmp/${USER}/build.julia-${VERSION}.${TARGET_HOST}"
SRC_DIR="${BUILD_DIR}/julia"

# ----------------------
# Verify parameters are correct before continuing.

# Abort the install if the prefix parent dir does not already exist when not
# building a test deployment.
if [[ "${TARGET_HOST}" != "test" ]] && [ ! -d "${JULIA_ROOT%/julia}" ]; then
  echo "!=> ERROR: Directory '${JULIA_ROOT%/julia}' does not exist."
  echo "           Is the target host correct?"
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

echo "==> Installing Julia"
echo "    Target Host:     ${TARGET_HOST}"
echo "    Version:         ${VERSION}"
echo "    Prefix:          ${PREFIX}"
echo "    Module Dir:      ${MODULE_ROOT}"
echo "    Module Name:     ${MODULE_NAME}"
echo "    Modulefile:      ${MODULE_FILE}"
echo "    Source dir:      ${SRC_DIR}"
echo ""
echo "    WARNING: DO NOT RUN THIS SCRIPT UNATTENDED"
echo "             This script requires interactive input"
echo ""

read -p "Are the above values correct? (y/[n]) " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  # handle exits from shell or function but don't exit interactive shell
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

# ----------------------
# Perform the build

# Bailout on first error
set -e

# Setup the build environment. Use the default GCC module.
module purge
module load gcc cmake git spectrum-mpi cuda

# Capture the specific gcc module used to set as a hard dependency in the modulefile.
GCC_DEPENDS="$(module -t list gcc)"

# Setup the build directory and sources.
# MUST be built in tmp - building in home or proj causes issues
mkdir -p "${BUILD_DIR}"
BUILD_DATE="$(\date --iso-8601=minutes)"
LOG_FILE="${BUILD_DIR}/build.${BUILD_DATE}.log"

echo "=> Beginning build of Julia v${VERSION} at ${BUILD_DATE}" | tee "${LOG_FILE}"
echo "=> Build environment:" | tee -a "${LOG_FILE}"
module --redirect -t list | tee -a "${LOG_FILE}"

if [ ! -f "${PREFIX}/bin/julia" ]; then
  # Julia binary does not exist. Build and install it.
  echo "=> Fetching sources" | tee -a "${LOG_FILE}"
  if [ ! -d ${SRC_DIR} ]; then
    git clone https://github.com/JuliaLang/julia \
              --single-branch \
              -b "v${VERSION}" \
              ${SRC_DIR}

cat <<EOF > ${SRC_DIR}/Make.user
USE_BINARYBUILDER=0
GCCPATH=${OLCF_GCC_ROOT}/lib64
LDFLAGS +=  -L${OLCF_GCC_ROOT}/lib64 -Wl,-rpath,${OLCF_GCC_ROOT}/lib64
EOF

    echo "=> ...Done!" | tee -a "${LOG_FILE}"
  else
    echo "=> Sources already exist at '${SRC_DIR}'." | tee -a "${LOG_FILE}"
  fi

  # Build and install Julia
  # TODO: Build appears to use relative RPATHs by default as well as hard RPATHs
  # to the build directory. Might consider adding RPATHs to the GCC runtime libs
  # so the module does not need the same build-time GCC module loaded at runtime.
  cd "${SRC_DIR}"
  echo "=> Starting build stage." | tee -a "${LOG_FILE}"
  make VERBOSE=1 prefix=${PREFIX} -j4 | tee -a "${LOG_FILE}"

  echo "=> Starting install stage." | tee -a "${LOG_FILE}"
  make VERBOSE=1 prefix=${PREFIX} install | tee -a "${LOG_FILE}"

  # Generate the modulefile
  # FIXME - Block/prompt user if modulefile already exists before overwritting.
  # eval `make print-JULIA_VERSION`
  echo "=> Generating modulefile" | tee -a "${LOG_FILE}"
  mkdir -p "${MODULE_FILE%/*}"

cat <<EOF > "${MODULE_FILE}"
whatis("Name : julia v${VERSION}")
whatis("Short description : The Julia programming language.")
help([[The Julia programming language.]])
depends_on("${GCC_DEPENDS}")
always_load("cmake")
add_property("state","experimental")
prepend_path("PATH","${PREFIX}/bin")
EOF

  # Install base extensions.
  echo "=> Installing base extensions" | tee -a "${LOG_FILE}"
  cd "${PREFIX}/bin"
  ./julia -e 'using Pkg; Pkg.API.precompile(); Pkg.add("MPI"); Pkg.add("CUDA")' | tee -a "${LOG_FILE}"

else # Install julia if binary not in prefix
  # Julia is already installed, update base extensions.
  echo "=> Updating base extensions" | tee -a "${LOG_FILE}"
  cd "${PREFIX}/bin"
  ./julia -e 'using Pkg; Pkg.API.precompile(); Pkg.add("MPI"); Pkg.add("CUDA")' | tee -a "${LOG_FILE}"
fi

echo "==> Build finished successfully" | tee -a "${LOG_FILE}"
cp "${LOG_FILE}" "${PREFIX}/build.${BUILD_DATE}.log"
