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


print_good '[START]' "Docker Script Execution"
printf '\n'

SCRIPT_LOCATION='/config/tf_customize/replace_brand.sh'
print_good '[DESCRIBE]' "Using script location: [${SCRIPT_LOCATION}]"

CONTAINER_ROW="$(docker ps --filter "ancestor=binhex/arch-jellyfin:latest" | head -n 2 | tail -n 1)"
print_good '[FOUND]' "Running Jellyfin Container Row: [${CONTAINER_ROW}]"

JF_CONTAINER_ID="$(echo "${CONTAINER_ROW}" | awk '{print $1}')"
print_good '[EXTRACTED]' "Jellyfin Container ID: [${JF_CONTAINER_ID}]\n"

if [ -z "${CONTAINER_ROW}" ] || [ 'CONTAINER' = "${JF_CONTAINER_ID}" ]; then
    print_bad '[ERROR]' 'No running Jellyfin container found'
    exit 1
fi

print_good '[RUNNING]' "Executing script [${SCRIPT_LOCATION}] in Jellyfin container [${JF_CONTAINER_ID}]\n"

printf '#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-\n'
docker exec -it "${JF_CONTAINER_ID}" /bin/sh -c "$SCRIPT_LOCATION"
printf '#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-#-\n'

printf '\n'
print_good '[END]' 'Docker Script Execution\n\n'



