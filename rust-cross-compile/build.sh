#!/usr/bin/env sh

BINARY_NAME=something
BUILD_MODE='release'    # 'debug'||'release'
CLEAN_BINARY_ACTIVE=0   # 0||1
COMPRESS_ACTIVE=0       # 0||1
PREBUILD_CLEAN_ACTIVE=1 # 0||1
APPLE_ARM_ACTIVE=1      # 0||1
APPLE_X86_ACTIVE=1      # 0||1
LINUX_ARM_ACTIVE=1      # 0||1
LINUX_X86_ACTIVE=1      # 0||1
WINDOWS_ARM_ACTIVE=0    # 0||1
WINDOWS_X86_ACTIVE=1    # 0||1



####################
## Prebuild Clean ##
####################
prebuild_clean() {
    if [ ${PREBUILD_CLEAN_ACTIVE} -eq 1 ];then
        printf '[STAGE]\t:: re-build Clean\n'
        cargo clean
        [ -d "${REPO_ROOT_DIR}/dist" ] && rm -rf "${REPO_ROOT_DIR}/dist"
    fi
}



##########################
## Build Target Locally ##
##########################
build_target_locally() {
    TARGET_LABEL="${1}"
    ABI_NAME="${2}"
    _BINARY_NAME="${BINARY_NAME}"
    DIST_DIR="${REPO_ROOT_DIR}/dist/${ABI_NAME}"
    TARGET_DIR="${REPO_ROOT_DIR}/target/${ABI_NAME}/${BUILD_MODE}"

    printf '[STAGE]\t:: %s\n' "${TARGET_LABEL}"

    if echo "${ABI_NAME}" | grep -iq 'windows'; then
        _BINARY_NAME="${_BINARY_NAME}.exe"
    fi

    [ -d "${DIST_DIR}" ] || mkdir -p "${DIST_DIR}"

    INSTALLED_TARGETS="$(rustup target list)"
    if ! echo "${INSTALLED_TARGETS}" | grep -iq "${ABI_NAME} (installed)"; then
        rustup target add "${ABI_NAME}"
    fi

    cargo build "--${BUILD_MODE}" --target "${ABI_NAME}"
    cp "${TARGET_DIR}/${_BINARY_NAME}" "${DIST_DIR}"

    if [ ${COMPRESS_ACTIVE} -eq 1 ]; then
        if ! command -v "tar" > /dev/null 2>&1; then
            printf '[ERROR]\t:: tar doesnt appear to be installed'
        else
            COPYFILE_DISABLE=1 tar -czpf "${DIST_DIR}/${_BINARY_NAME}.tar.gz" -C "${DIST_DIR}" "${_BINARY_NAME}"
        fi
    fi

    if [ ${CLEAN_BINARY_ACTIVE} -eq 1 ]; then
        rm "${DIST_DIR}/${_BINARY_NAME}"
    fi

    _BINARY_NAME=
    ABI_NAME=
    DIST_DIR=
    TARGET_DIR=
    INSTALLED_TARGETS=
}



################################
## Build Target Containerized ##
################################
build_target_containerized() {
    TARGET_LABEL="${1}"
    ABI_NAME="${2}"
    PLATFORM="${3}"
    CONTAINER_IMAGE="${4}"
    _BINARY_NAME="${BINARY_NAME}"
    DOCKER_CONTAINER="${ABI_NAME}-builder"
    DIST_DIR="${REPO_ROOT_DIR}/dist/${ABI_NAME}"
    REMOTE_DIST_DIR="/app/dist/${ABI_NAME}"
    TARGET_DIR="${REPO_ROOT_DIR}/target/${ABI_NAME}/${BUILD_MODE}"
    REMOTE_TARGET_DIR="/app/target/${ABI_NAME}/${BUILD_MODE}"

    printf '[STAGE]\t:: %s\n' "${TARGET_LABEL}"

    if ! command -v "docker" > /dev/null 2>&1; then
        printf '[ERROR]\t:: docker doesnt appear to be installed'
        return
    fi

    docker rm -f "${DOCKER_CONTAINER}" > /dev/null 2>&1

    docker create -it \
    --name "${DOCKER_CONTAINER}" \
    --platform "${PLATFORM}" \
    -v "${REPO_ROOT_DIR}/Cargo.toml":/app/Cargo.toml:ro \
    -v "${REPO_ROOT_DIR}/Cargo.lock":/app/Cargo.lock:ro \
    -v "${REPO_ROOT_DIR}/_init":/app/_init:ro \
    -v "${REPO_ROOT_DIR}/build.rs":/app/build.rs:ro \
    -v "${REPO_ROOT_DIR}/src":/app/src:ro \
    -v "${REPO_ROOT_DIR}/dist":/app/dist \
    -w /app \
    "${CONTAINER_IMAGE}"

    docker start "${DOCKER_CONTAINER}"

    docker exec -it "${DOCKER_CONTAINER}" bash -c "$(cat <<EOF
        set -e;
        cargo build --${BUILD_MODE} --target ${ABI_NAME};
        [ -d "${REMOTE_DIST_DIR}" ] || mkdir -p "${REMOTE_DIST_DIR}";
        cp ${REMOTE_TARGET_DIR}/${_BINARY_NAME} ${REMOTE_DIST_DIR};
EOF
    )" 2>/dev/null

    docker rm -f "${DOCKER_CONTAINER}" > /dev/null 2>&1

    if [ ${COMPRESS_ACTIVE} -eq 1 ]; then
        if ! command -v "tar" > /dev/null 2>&1; then
            printf '[ERROR]\t:: tar doesnt appear to be installed'
        else
            COPYFILE_DISABLE=1 tar -czpf "${DIST_DIR}/${_BINARY_NAME}.tar.gz" -C "${DIST_DIR}" "${_BINARY_NAME}"
        fi
    fi

    if [ ${CLEAN_BINARY_ACTIVE} -eq 1 ]; then
        rm "${DIST_DIR}/${_BINARY_NAME}"
    fi

    _BINARY_NAME=
    DOCKER_CONTAINER=
    PLATFORM=
    ABI_NAME=
    DIST_DIR=
    REMOTE_DIST_DIR=
    TARGET_DIR=
    REMOTE_TARGET_DIR=
    INSTALLED_TARGETS=

}



####################
## Main Execution ##
####################
printf '[STAGE]\t:: Where am i?\n'
if git rev-parse --show-toplevel > /dev/null 2>&1; then
    REPO_ROOT_DIR="$(git rev-parse --show-toplevel)"
else
    FULL_0="$( readlink -f "${0}" )"
    SCRIPT_DIR_BASENAME="$( basename "$( dirname "$( readlink -f "${0}" )" )" )"
    SCRIPT_FILE="$( basename "$( readlink -f "${0}" )" )"
    RELATIVE_0="${SCRIPT_DIR_BASENAME}/${SCRIPT_FILE}"
    REPO_ROOT_DIR="${FULL_0%%"${RELATIVE_0}"}"
fi
cd "${REPO_ROOT_DIR}" || exit 1
printf '[INFO]\t:: %s\n' "${REPO_ROOT_DIR}"

prebuild_clean
[ ${APPLE_ARM_ACTIVE}   -eq 1 ] && build_target_locally       'Apple ARM'      'aarch64-apple-darwin'
[ ${APPLE_X86_ACTIVE}   -eq 1 ] && build_target_locally       'Apple x86_64'   'x86_64-apple-darwin'
[ ${LINUX_ARM_ACTIVE}   -eq 1 ] && build_target_containerized 'Linux ARM'      'aarch64-unknown-linux-gnu'  'linux/arm64' 'rust:slim-bookworm'
[ ${LINUX_X86_ACTIVE}   -eq 1 ] && build_target_containerized 'Linux ARM'      'x86_64-unknown-linux-gnu'   'linux/amd64' 'rust:slim-bookworm'
[ ${WINDOWS_ARM_ACTIVE} -eq 1 ] && build_target_locally       'Windows ARM'    'aarch64-pc-windows-gnullvm'
[ ${WINDOWS_X86_ACTIVE} -eq 1 ] && build_target_locally       'Windows x86_64' 'x86_64-pc-windows-gnu'


