#! /usr/bin/env sh

# Perform the entire Python execution routine
# Includes:
#   Ensuring script execution is within the repository
#   Export the environment variables set in configuration/environment.properties
#   Perform Pre-Python dependency checks and installed
#   Then execute the Python routine

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
    printf '[INFO]\t[PY_ENV] "%s" does exist\n' "${FULL_PYVENV_LOCATION}"
    # shellcheck disable=SC1091
    . "${FULL_PYVENV_LOCATION}/bin/activate"
fi

if [ ! -d "${FULL_PYVENV_LOCATION}" ]; then
    printf '[INFO]\t[PY_ENV] Virtual Environment: "%s" does not exist\n' "${FULL_PYVENV_LOCATION}"
    /usr/bin/env python3 -m venv "${FULL_PYVENV_LOCATION}"
    printf '[INFO]\t[PY_ENV] Virtual Environment: "%s" Created\n' "${FULL_PYVENV_LOCATION}"
    # shellcheck disable=SC1091
    . "${FULL_PYVENV_LOCATION}/bin/activate"
    printf '[INFO]\t[PY_ENV] Virtual Environment: "%s" Activated\n' "${FULL_PYVENV_LOCATION}"
    # shellcheck disable=SC2086
    "${FULL_PYVENV_LOCATION}/bin/python" -m pip install ${QUIET} --upgrade pip
fi

# shellcheck disable=SC2086
"${FULL_PYVENV_LOCATION}/bin/python" -m pip install ${QUIET} --requirement "${REPO_ROOT_DIR}/requirements.txt"

if [ "${REFREEZE_REQUIREMENTS}" = 'TRUE' ]; then
    printf "[INFO]\t[PY_ENV] Re-Freezing the Requirements file\n"
    "${FULL_PYVENV_LOCATION}/bin/python" -m pip freeze > "${REPO_ROOT_DIR}/requirements.txt"
fi


"${FULL_PYVENV_LOCATION}/bin/python" -Bu "${REPO_ROOT_DIR}/python/main.py" "${@}"
