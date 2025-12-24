#!/usr/bin/env sh

print_bad() {
    HEADER="${1:-ERROR}"
    MESSAGE="${2}"
    printf "\033[0;31m%s\033[0m %s\n" "${HEADER}" "${MESSAGE}"
}

print_good() {
    HEADER="${1:-SUCCESS}"
    MESSAGE="${2}"
    printf "\033[92m%s\033[0m %s\n" "${HEADER}" "${MESSAGE}"
}

print_attn() {
    HEADER="${1:-ATTENTION}"
    MESSAGE="${2}"
    printf "\033[93m%s\033[0m %s\n" "${HEADER}" "${MESSAGE}"
}

print_good '[START]' 'Logo Injection Script'
printf '\n'
NEW_BANNER_IMAGE="/config/tf_customize/custom_jellyfin_images/TRISFLIX_LOGO.png"
JELLYFIN_WEB_DIR="/usr/share/jellyfin/web"
REPLACE_TARGET_DARK_BANNER="$(find "${JELLYFIN_WEB_DIR}" -name "banner-dark*.png")"
REPLACE_TARGET_LIGHT_BANNER="$(find "${JELLYFIN_WEB_DIR}" -name "banner-light*.png")"

if ! command -v sha1sum > /dev/null 2>&1 ; then
    print_bad '[ERROR] :: sha1sum could not be found\n'
    exit 1
else
    print_good '[FOUND]' "sha1sum :: $(which sha1sum)"
fi

print_good '[DESCRIBE RESOURCES]'
printf '"NEW_BANNER_IMAGE"\t\t:: %s\n"REPLACE_TARGET_DARK_BANNER"\t:: %s\n"REPLACE_TARGET_LIGHT_BANNER"\t:: %s\n' "${NEW_BANNER_IMAGE}" "${REPLACE_TARGET_DARK_BANNER}" "${REPLACE_TARGET_LIGHT_BANNER}"

TF_SHA=''
if [ -n "${NEW_BANNER_IMAGE}" ] && [ -f "${NEW_BANNER_IMAGE}" ]; then
    print_good '[FOUND]' "CUSTOM BANNER :: ${NEW_BANNER_IMAGE}"
    TF_SHA=$(sha1sum "${NEW_BANNER_IMAGE}" | awk '{print $1}')
    if [ -z "${TF_SHA}" ]; then
        print_bad '[ERROR]' "CUSTOM BANNER :: sha1sum could not be generated"
        exit 1
    fi
else
    print_bad '[NOT FOUND]' "CUSTOM BANNER :: ${NEW_BANNER_IMAGE}"
    exit 1
fi

DARK_SHA=''
if [ -n "${REPLACE_TARGET_DARK_BANNER}" ] && [ -f "${REPLACE_TARGET_DARK_BANNER}" ]; then
    print_good '[FOUND]' "DARK BANNER :: ${REPLACE_TARGET_DARK_BANNER}"
    DARK_SHA=$(sha1sum "${REPLACE_TARGET_DARK_BANNER}" | awk '{print $1}')
    if [ -z "${DARK_SHA}" ]; then
        print_bad '[ERROR]' "DARK BANNER :: sha1sum could not be generated"
        exit 1
    fi

    if [ "${TF_SHA}" != "${DARK_SHA}" ]; then
        BACKUP_DARK="${REPLACE_TARGET_DARK_BANNER}.bak"
        print_good '[FOUND]' "DARK BANNER :: \"${REPLACE_TARGET_DARK_BANNER}\" backing up to \"${BACKUP_DARK}\""
        mv "${REPLACE_TARGET_DARK_BANNER}" "${BACKUP_DARK}"
        print_good '[REPLACING]' "DARK BANNER:: \"${REPLACE_TARGET_DARK_BANNER}\" with \"${NEW_BANNER_IMAGE}\""
        cp "${NEW_BANNER_IMAGE}" "${REPLACE_TARGET_DARK_BANNER}"
    else
        print_good '[SHA MATCHED]' "DARK BANNER :: ${REPLACE_TARGET_DARK_BANNER}:${DARK_SHA} == ${NEW_BANNER_IMAGE}:${TF_SHA}"
        print_attn '[SKIPPING]' "DARK BANNER :: \"${REPLACE_TARGET_DARK_BANNER}\""
    fi

else
    print_bad '[NOT FOUND]' "DARK BANNER :: ${REPLACE_TARGET_DARK_BANNER}"
fi

LIGHT_SHA=''
if [ -n "${REPLACE_TARGET_LIGHT_BANNER}" ] && [ -f "${REPLACE_TARGET_LIGHT_BANNER}" ]; then
    print_good '[FOUND]' "LIGHT BANNER :: ${REPLACE_TARGET_LIGHT_BANNER}"
    LIGHT_SHA=$(sha1sum "${REPLACE_TARGET_LIGHT_BANNER}" | awk '{print $1}')
    if [ -z "${LIGHT_SHA}" ]; then
        print_bad '[ERROR]' "LIGHT BANNER :: sha1sum could not be generated"
        exit 1
    fi

    if [ "${TF_SHA}" != "${LIGHT_SHA}" ]; then
        BACKUP_LIGHT="${REPLACE_TARGET_LIGHT_BANNER}.bak"
        print_good '[FOUND]' "LIGHT BANNER :: \"${REPLACE_TARGET_LIGHT_BANNER}\" backing up to \"${BACKUP_LIGHT}\""
        mv "${REPLACE_TARGET_LIGHT_BANNER}" "${BACKUP_LIGHT}"
        print_good '[REPLACING]' "LIGHT BANNER:: \"${REPLACE_TARGET_LIGHT_BANNER}\" with \"${NEW_BANNER_IMAGE}\""
        cp "${NEW_BANNER_IMAGE}" "${REPLACE_TARGET_LIGHT_BANNER}"
    else
        print_good '[SHA MATCHED]' "LIGHT BANNER :: ${REPLACE_TARGET_LIGHT_BANNER}:${LIGHT_SHA} == ${NEW_BANNER_IMAGE}:${TF_SHA}"
        print_attn '[SKIPPING]' "LIGHT BANNER :: \"${REPLACE_TARGET_LIGHT_BANNER}\""
    fi
else
    print_bad '[NOT FOUND]' "LIGHT BANNER :: ${REPLACE_TARGET_LIGHT_BANNER}"
fi

print_good '[COMPLETE]' 'Logo Injection Script'
printf '\n'