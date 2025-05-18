#!/usr/bin/env sh

# Perform the script execution and all the container tasks
# Includes:
#   Ensuring script execution is within the repository
#   Getting repository changes
#   Rebuilding Docker image if there were any git changes
#   Run the shell/run.sh script in a disposable docker container

if [ ! "$(command -v docker)" ]; then
    printf "[ERROR]\t[DOCKER] There is no \"docker\" command in the PATH!\n"
    exit 1
fi

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

PREVIOUS_COMMIT=$(git rev-list HEAD -n 1)

if [ "${LOG_LEVEL}" != "DEBUG" ]; then
    QUIET="--quiet"
fi

if [ "${AUTO_UPDATE}" = 'TRUE' ]; then
    printf "[INFO]\t[GIT]    Update git repository (Pull)\n"
    git pull "${QUIET}"
fi

DOCKER_NAME="${DOCKER_NAME:-python_wrapper}"

# shellcheck disable=SC2086
if [ -z "$(docker images -q ${DOCKER_NAME}:latest 2> /dev/null)" ] || [ "${PREVIOUS_COMMIT}" != "$(git rev-list HEAD -n 1)" ] || [ "${FORCE_DOCKER_REBUILD}" = 'TRUE' ]; then
    [ "${FORCE_DOCKER_REBUILD}"  = 'TRUE' ] && printf "[INFO]\t[DOCKER] FORCE_DOCKER_REBUILD is active .......... Rebuilding image\n"
    [ "${FORCE_DOCKER_REBUILD}" != 'TRUE' ] && printf "[INFO]\t[DOCKER] Found changes to %s .......... Rebuilding image\n" "${DOCKER_NAME}"
    "${REPO_ROOT_DIR}/shell/build_image.sh"
else
    printf "[INFO]\t[DOCKER] No changes to %s\n" "${DOCKER_NAME}"
    if [ -d "${FULL_PYVENV_LOCATION}" ]; then
        printf "[INFO]\t[DOCKER] Clear existing virtual environment at %s\n" "${FULL_PYVENV_LOCATION}"
        [ "$(command -v deactivate)" ] && deactivate
        rm -rf "${FULL_PYVENV_LOCATION:?}"
    fi
fi

printf "[INFO]\t[DOCKER] Start the Docker run for %s:latest\n" "${DOCKER_NAME}"
docker run "${QUIET}" --env-file "${REPO_ROOT_DIR}/configuration/environment.properties" --rm --name "${DOCKER_NAME}" "${DOCKER_NAME}:latest" "${REPO_ROOT_DIR}/shell/run.sh" "${@}"