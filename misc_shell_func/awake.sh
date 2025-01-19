#! /usr/bin/env sh
 
awake(){
 
	if ! command -v caffeinate > /dev/null 2>&1; then 
		printf '[ERROR] no caffeinate available on this system\n'; 
		return 1
	fi

	HELP="Usage: awake [on|off]"
	ERR="[INVALID ARG]: Must pass exactly 1 arg [on|off]"

	if [ ${#} -ne 1 ] || { [ "${1}" != "on" ] && [ "${1}" != "off" ]; };then
		printf "%s\n\t%s\n" "${HELP}" "${ERR}"
		return 1
	fi

	if [ "${1}" = "on" ] && [ -z "$(pgrep caffeinate)" ];then
		printf "(-‿-)\r"
		sleep .5
		printf "(ಠ_ಠ)\r"
		sleep .3
		# shellcheck disable=SC2091
		$(nohup -- /usr/bin/caffeinate -disu > /dev/null 2>&1 &)
		return 0

	fi

	if [ "${1}" = "off" ] && [ -n "$(pgrep caffeinate)" ];then
		printf "(ಠ_ಠ)\r"
		sleep .5
		printf "(-‿-)\r"
		sleep .3
		kill $(pgrep caffeinate)
		return 0
	fi
}