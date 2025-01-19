#! /usr/bin/env sh

# Execute whatever is in the paseboard
encrypt(){
	IN_FILE="${1}"
	OUT_FILE="${IN_FILE}.enc"
	TMPDIR="$(readlink -f "${TMPDIR:-/tmp}")"

	if ! command -v openssl > /dev/null 2>&1; then
		printf 'ERROR: No openssl binary in the current PATH'
		exit 1
	fi

	if [ -z "${IN_FILE}" ]; then
		printf 'ERROR: Missing required parameter\n\t%s\n' 'usage: encrypt [file]'
		return 1
	fi

	if [ -d "${IN_FILE}" ]; then
		ZIP_FILE="${TMPDIR}/${IN_FILE}.zip"

		if ! command -v zip > /dev/null 2>&1; then
			printf 'ERROR: No zip binary in the current PATH'
			exit 1
		fi

		zip -qr "${ZIP_FILE}" "${IN_FILE}"
		IN_FILE="${ZIP_FILE}"
	fi

	openssl enc -e -aes-256-cbc -pbkdf2 -in "${IN_FILE}" -out "${OUT_FILE}"
	rm -f "${ZIP_FILE}"
}

decrypt(){
	IN_FILE="${1}"
	TMPDIR="$(readlink -f "${TMPDIR:-$(mktemp -d)}")"

	if [ -z "${IN_FILE}" ]; then
		printf 'ERROR: Missing required parameter\n\tusage: decrypt [file]\n'
		return 1
	fi

	# field 1 delimited by '.'s
	FILENAME="$(basename "$IN_FILE" | cut -d. -f1)"
	# field 2-LAST delimited by '.'s (expecting 2 extensions <EXT>.enc from encrypt())
	EXTENSIONS="$(basename "$IN_FILE" | cut -d. -f2-)"
	# field 1 delimited by '.'s (of the extensions)
	EXTENSION="$(basename "$EXTENSIONS" | cut -d. -f1)"
	# field w delimited by '.'s of the extensions ("enc" expected)
	ENC="$(basename "$EXTENSIONS" | cut -d. -f2)"

	if [ -z "${EXTENSION}" ] || [ -z "${ENC}" ];then
		printf 'ERROR: Extensions arnt in expected format...\n\text: $s\n\tenc: $s'
		return 1
	fi

	OUT_FILE="${FILENAME}.${EXTENSION}"
	openssl enc -d -aes-256-cbc -pbkdf2 -in "${IN_FILE}" -out "${TMPDIR}/${OUT_FILE}"

	if [ "${EXTENSION}" = 'zip' ];then
		unzip -q "${TMPDIR}/${OUT_FILE}"
		rm -f "${TMPDIR}/${OUT_FILE}"
	else
		mv "${TMPDIR}/${OUT_FILE}" ./
	fi
}