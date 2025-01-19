#! /usr/bin/env sh

# Execute whatever is in the paseboard
pbexec(){
	# Add trailing newline & Trim leading/trailing whitespace
	PASTE=$(printf '%s\n' "$(pbpaste)" | awk '{$1=$1};1')
	# Escape special shell characters
	PASTE=$(printf '%s' "${PASTE}" | sed "s/[\\&\`\"'$\|!;*?(){}[\]<>]/\\&/g")
	if [ "${PASTE}" = 'pbexec' ]; then
		printf '[INVALID ARG] Circular call! content == "pbexec"\n' 
		return 1
	fi
	while IFS= read -r LINE; do
		eval ${LINE}; 
	done  << EOF
${PASTE}
EOF
}

