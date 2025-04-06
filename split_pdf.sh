#!/bin/bash

# Title - split_pdf 
# Version - 1.3
# Description - A Bash script to split a PDF file based on the ranges provided in a CSV file. 
# Author - Pedro Sánchez Uscamaita
# GitHub Repository - github.com/pjfsu/split_pdf
# DockerHub Repository - hub.docker.com/repository/docker/pjfsu/split_pdf
# License - GPLv3
# Year - 2024
# City - A Coruña, A Coruña, Galicia, Spain

# This program is free software: you can redistribute it and/or 
# modify it under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version. 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details. 
# You should have received a copy of the GNU General Public License 
# along with this program. If not, see <http://www.gnu.org/licenses/>.

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

file_not_found_or_empty() {
	local -r FILE="${1}"
	local -ri CODE=17
	local -r MSG="file \"${FILE}\" not found or empty." 
	error ${CODE} "${MSG}"
}

read_permission_not_found() {
	local -r FILE="${1}"
	local -ri CODE=19
	local -r MSG="file \"${FILE}\" has no read permission."
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

# core
run() {
	local -r IN_PDF="${1}"
	local -r IN_CSV="${2}"
	local -r OUT_DIR="${3}"
	podman run \
		--rm \
		-v "./${IN_PDF}:/tmp/in.pdf" \
		-v "./${IN_CSV}:/tmp/in.csv" \
		-v "./${OUT_DIR}:/tmp/out" \
		docker.io/pjfsu/split_pdf:main
}

# entry point
main() {
	# guard
	local -r REQUIRED_COMMANDS=( podman printf dirname mkdir )
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
		[ -s "${file}" ] || file_not_found_or_empty "${file}"
		[ -r "${file}" ] || read_permission_not_found "${file}"
	done

	local -r IN_PDF_DIR="$(dirname "${IN_PDF}")"
	[ -w "${IN_PDF_DIR}" ] || write_permission_not_found "${IN_PDF_DIR}" 

	local -r OUT_DIR="${IN_PDF%.pdf}" # OUT_DIR name = IN_PDF name without the extension .pdf
	[ -d "${OUT_DIR}" ] || mkdir "${OUT_DIR}" # OUT_DIR dirname = IN_PDF dirname

	# split
	run "${IN_PDF}" "${IN_CSV}" "${OUT_DIR}"
}

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
main "${@}"
