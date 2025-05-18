#! /usr/bin/env sh

# Export the environment variables set in configuration/environment.properties
# and set the indicator that the importing has been done to prevent redundant executions

if [ -z "${ALREADY_SOURCED}" ]; then
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

    printf "[INFO]\t[SH_ENV] Exporting configuration/environment.properties variables:\n"
    while read -r VARIABLE || [ -n "${VARIABLE}" ]; do
        if [ "${VARIABLE%"${VARIABLE#?}"}" = "#" ] || [ "${VARIABLE}" = '' ]; then
            continue
        else
            printf "[INFO]\t[SH_ENV] >>\t %s\n" "${VARIABLE?}"
            export "${VARIABLE:?[ERROR] export failed in source_environment.sh!}"
        fi
    done < "${REPO_ROOT_DIR}/configuration/environment.properties"

    export ALREADY_SOURCED=TRUE
else
    printf "[INFO]\t[SH_ENV] Skipping additional sourcing because ALREADY_SOURCED is defined\n"
fi
