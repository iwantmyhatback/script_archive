#! /usr/bin/env sh

# Delete existing Docker image and rebuild the image with current files
# Can be used when testing adhoc, but is also used by shell/run_docker.sh in deployments

if git rev-parse --show-toplevel > /dev/null 2>&1; then
    REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"
else
    FULL_0="$( readlink -f "${0}" )"
    # Needed because this script is nested 1 level down from the root
    SCRIPT_DIR_BASENAME="$( basename "$( dirname "$( readlink -f "${0}" )" )" )"
    SCRIPT_FILE="$( basename "$( readlink -f "${0}" )" )"
    RELATIVE_0="${SCRIPT_DIR_BASENAME}/${SCRIPT_FILE}"
    REPO_ROOT_DIR="${FULL_0%%"${RELATIVE_0}"}"
fi
cd "${REPO_ROOT_DIR}" || exit 1

# shellcheck disable=SC1091
. "${REPO_ROOT_DIR}/shell/source_environment.sh"

PYVENV_LOCATION="${PYVENV_LOCATION:-py_venv}"
FULL_PYVENV_LOCATION="${REPO_ROOT_DIR}/${PYVENV_LOCATION}"

if [ "${LOG_LEVEL}" != "DEBUG" ]; then
    QUIET="--quiet"
fi

if [ -d "${FULL_PYVENV_LOCATION}" ]; then
    printf "[INFO]\t[DOCKER] Clear existing virtual environment at %s\n" "${FULL_PYVENV_LOCATION}"
    [ "$(command -v deactivate)" ] && deactivate
    rm -rf "${FULL_PYVENV_LOCATION:?}"
fi

if [ "${AUTO_UPDATE}" = 'TRUE' ]; then
    printf "[INFO]\t[DOCKER] Update Docker Python image (Pull)\n"
    docker pull "${QUIET}" python:latest
fi

DOCKER_NAME="${DOCKER_NAME:-python_wrapper}"

printf "[INFO]\t[DOCKER] Remove old %s image\n" "${DOCKER_NAME}"
docker image rm "${DOCKER_NAME}" --force > /dev/null 2>&1

printf "[INFO]\t[DOCKER] Build new %s image\n" "${DOCKER_NAME}"
docker build "${QUIET}" --build-arg PYVENV_LOCATION="${PYVENV_LOCATION}" --build-arg DIRNAME="${REPO_ROOT_DIR}" -t "${DOCKER_NAME}" ./