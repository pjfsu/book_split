set -o errexit -o nounset -o pipefail

# errors
command_not_found() {
	local -r CMD="${1}"
	local -r MSG="${CMD} command not found"
	local -ri CODE=11
	error ${CODE} "${MSG}"
}

args_len_not_valid() {
	local -ri EXPECTED_ARGS_LEN=${1}
	local -ri GIVEN_ARGS_LEN=${2}
	local -ri CODE=13
	local -r MSG="expected ${EXPECTED_ARGS_LEN} files, given ${GIVEN_ARGS_LEN}. Usage: \"./split_pdf.sh PDF CSV\""
	error ${CODE} "${MSG}"
}

file_not_found() {
	local -r FILE="${1}"
	local -ri CODE=17
	local -r MSG="file \"${FILE}\" not found." 
	error ${CODE} "${MSG}"
}

read_permission_not_found() {
	local -r FILE="${1}"
	local -ri CODE=19
	local -r MSG="file \"${FILE}\" with no read permission."
	error ${CODE} "${MSG}"
}

write_permission_not_found() {
	local -r FILE="${1}"
	local -ri CODE=23
	local -r MSG="file \"${FILE}\" has no write permission."
	error ${CODE} "${MSG}"
}

error() {
	local -r CODE=$1
	local -r MSG="$2"
	printf "[ERROR %i] %s\n" $CODE "$MSG" >&2
	exit $CODE
}

main() {
	# guard
	local -r REQUIRED_COMMANDS=( dirname podman mkdir )
	for cmd in "${REQUIRED_COMMANDS[@]}"
	do
		command -v "${cmd}" > /dev/null || command_not_found "${cmd}"
	done

	local -r ARGS_LEN=2
	[ ${#} -eq ${ARGS_LEN} ] || args_len_not_valid ${ARGS_LEN} ${#}

	local -r IN_PDF=${1}
	local -r IN_CSV=${2}
	for file in "${IN_PDF}" "${IN_CSV}"
	do
		[ -f "${file}" ] || file_not_found "${file}"
		[ -r "${file}" ] || read_permission_not_found "${file}"
	done

	local -r IN_PDF_DIR="$(dirname "${IN_PDF}")"
	[ -w "${IN_PDF_DIR}" ] || write_permission_not_found "${IN_PDF_DIR}" 

	local -r OUT_DIR="${IN_PDF%.pdf}" # remove the extension .pdf
	[ -d "${OUT_DIR}" ] || mkdir "${OUT_DIR}" # OUT_DIR dirname = IN_PDF dirname

	# split
	podman run \
		-d \
		--rm \
		-v "./${IN_PDF}:/tmp/in.pdf" \
		-v "./${IN_CSV}:/tmp/in.csv" \
		-v "./${OUT_DIR}:/tmp/out" \
		localhost/split_pdf
}

main "${@}"
