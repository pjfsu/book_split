#!/bin/bash

# Title - split_pdf 
# Version - 1.3
# Description - A Bash script to split a PDF file based on the ranges provided in a CSV file. 
# Author - Pedro Sánchez Uscamaita
# Repository - github.com/pjfsu/split_pdf
# License - GPLv3
# Year - 2024
# City - A Coruña, A Coruña

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

set -oue pipefail

# errors
args_len_not_valid() {
	local -ri EXPECTED_ARGS_LEN=${1}
	local -ri GIVEN_ARGS_LEN=${2}
	local -ri CODE=11
	local -r MSG="expected ${EXPECTED_ARGS_LEN} files, given ${GIVEN_ARGS_LEN}. Usage: \"./split_pdf.sh CSV\""
	error ${CODE} "${MSG}"
}

file_not_found() {
	local -r FILE="${1}"
	local -ri CODE=13
	local -r MSG="file \"${FILE}\" not found." 
	error ${CODE} "${MSG}"
}

read_permission_not_found() {
	local -r FILE="${1}"
	local -ri CODE=17
	local -r MSG="file \"${FILE}\" with no read permission."
	error ${CODE} "${MSG}"
}

pdf_not_valid() {
	local -r FILE="${1}"
	local -ri CODE=19
	local -r MSG="file \"${FILE}\" is not a valid PDF file." 
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

# warnings
invalid_rows() {
	local -r INVALID_ROWS="${1}"
	local -r MSG="invalid rows:
       	${INVALID_ROWS}
       	because:
	I. 1st col is not a positive integer, or
	II. 2nd col is not a positive integer, or
	III. 3nd col is an empty string"
	warning "${MSG}"
}

warning() {
	local -r MSG="${1}"
	printf "[WARNING] %s\n" "${MSG}" >&2
}

# debug
guard_debug() {
	echo -e "IN_PDF\t${IN_PDF}"
	echo -e "IN_CSV\t${IN_CSV}"
	echo -e "OUT_DIR\t${OUT_DIR}"
}

split_debug() {
	echo -e "from_page\t${from_page}"
	echo -e "to_page\t\t${to_page}"
	echo -e "IN_PDF_PAGES\t${IN_PDF_PAGES}"
	echo -e "out_pdf\t${out_pdf}"
	ls "${OUT_DIR}"
}

# entry point
main() {
	# guard
	local -r ARGS_LEN=2
	[ ${#} -eq ${ARGS_LEN} ] || args_len_not_valid ${ARGS_LEN} ${#}
	local -r IN_PDF=${1}
	local -r IN_CSV=${2}
	[ -f "${IN_CSV}" ] || file_not_found "${IN_CSV}"
	[ -f "${IN_PDF}" ] || file_not_found "${IN_PDF}"
	[ -r "${IN_CSV}" ] || read_permission_not_found "${IN_CSV}"
	[ -r "${IN_PDF}" ] || read_permission_not_found "${IN_PDF}"
	pdfinfo "${IN_PDF}" > /dev/null || pdf_not_valid "${IN_PDF}"
	local -r IN_PDF_DIR="$(dirname "${IN_PDF}")"
	[ -w "${IN_PDF_DIR}" ] || write_permission_not_found "${IN_PDF_DIR}" 
	local -r OUT_DIR="${IN_PDF%.pdf}" # remove the extension .pdf
	[ -d "${OUT_DIR}" ] || mkdir "${OUT_DIR}" # OUT_DIR dirname = IN_PDF dirname
	guard_debug
	# split
	local -r POS_INT_RE="[[:space:]]*[1-9][0-9]*[[:space:]]*"
	local -r NON_EMPTY_STR_RE="[[:space:]]*[^[:space:]].*"
	local -r VALID_CSV_ROW_RE="^${POS_INT_RE},${POS_INT_RE},${NON_EMPTY_STR_RE}$"
	local -ri IN_PDF_PAGES=$(pdfinfo "${IN_PDF}" | grep "Pages:" | cut -d: -f2)
	# a row is valid iff:
	# i. 1st col > 0
	# ii. 2nd col > 0
	# iii. 3rd col != ""
	# iv. 1st col <= 2nd col
	# v. 2nd col <= pdf total pages
	# note: if row len >= 3, then from 3rd col to the last one are used as out_pdf name
	grep "${VALID_CSV_ROW_RE}" "${IN_CSV}" | while IFS=, read -r from_page to_page out_pdf
	do
		[ ${from_page} -le ${to_page} ] || ( from_page_gt_to_page ${from_page} ${to_page} && continue )
		[ ${to_page} -le ${IN_PDF_PAGES} ] || ( to_page_gt_in_pdf_pages ${to_page} ${IN_PDF_PAGES} && continue )
		pdftk "${IN_PDF}" cat ${from_page}-${to_page} output "${OUT_DIR}/${out_pdf}.pdf"
		split_debug
	done
	local -r INVALID_ROWS="$( grep -v "${VALID_CSV_ROW_RE}" "${IN_CSV}" )"
	[ -z "${INVALID_ROWS}" ] || invalid_rows "${INVALID_ROWS}"
}

main "${@}"
