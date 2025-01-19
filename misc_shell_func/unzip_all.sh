#! /usr/bin/env sh

unzip_all() {
	# Leave this alone for the output formatting
	USAGE="Usage: unzip_all SOURCE_DIR [DEST_DIR]
SOURCE_DIR	| REQUIRED |  Location to look for ZIP files
DEST_DIR	| OPTIONAL |  Location to output extracted files.
			      If ommited output will go to \"SOURCE_DIR-unpacked\" in current working directory"

	if [ -d "$1" ]; then
		SOURCE_DIR="${1}"
	else
		printf '%s\n' "${USAGE}"
		return 1
	fi

	if [ -n "$2" ]; then
		DEST_DIR="${2}"
	else
		DEST_DIR="${1}-unpacked"
	fi

	mkdir -p "${DEST_DIR}"
	printf '\n[WORKING]: %s\n' "$(pwd)"
	printf '[SOURCE]: %s\n' "${SOURCE_DIR}"
	printf '[DEST]: %s\n\n' "${DEST_DIR}"

	for FILE in "${SOURCE_DIR}"/*.zip; do
		(
			printf '[UNPACK START] %s\n' "${FILE}"
			unzip -qj "${FILE}" -d "${DEST_DIR}"
			printf '[UNPACK FINISH] %s\n' "${FILE}"
		) &
	done

	printf '[WAIT] Waiting for all threads\n' 
	wait
	printf '[WAIT] Done waiting!\n' 

	printf '[SCRIPT COMPLETE]\n' 
}