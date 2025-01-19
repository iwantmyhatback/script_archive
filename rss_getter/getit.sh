#!/usr/bin/env sh

PODCAST="${1}"
set -- 'bonfire' 'mssp'
ARCHIVE_FILE="./resources/${PODCAST}_archive.txt"
URL_FILE="./resources/${PODCAST}_url.txt"
OUTPUT_DIRECTORY="./output"


FOUND=1
for ACCEPTED in "$@"
do
  [ "${ACCEPTED}" = "${PODCAST}" ] && FOUND=0
done

if [ -z "${PODCAST}" ];then
    printf '%s\n' "[ERROR] Podcast argument required: \"${*}\""
    exit 1
fi

if [ $FOUND -eq 1 ];then
    printf '%s\n' "[ERROR] Podcast not found in accepted list: \"${*}\""
    exit 1
fi

if [ -f "${ARCHIVE_FILE}" ];then
    printf '[FOUND] Archive file: %s\n' "${ARCHIVE_FILE}"
else
    printf '[NOT FOUND] Archive file: %s\n' "${ARCHIVE_FILE}"
    touch "${ARCHIVE_FILE}"
    printf '[CREATED] Archive file: %s\n' "${ARCHIVE_FILE}"
fi

if [ -f "${URL_FILE}" ];then
    printf '[FOUND] URL file: %s\n' "${URL_FILE}"
else
    printf '[NOT FOUND] URL file: %s\n' "${URL_FILE}"
    printf '[ABORTING] Cannot download without URL'
    exit 1
fi

[ ! -d "${OUTPUT_DIRECTORY}" ] && mkdir -p "${OUTPUT_DIRECTORY}"
yt-dlp -o "${OUTPUT_DIRECTORY}/%(title)s.%(ext)s" --download-archive "${ARCHIVE_FILE}" -N 2 "$(cat ${URL_FILE})"