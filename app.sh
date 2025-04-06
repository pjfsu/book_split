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

set -oue pipefail

# errors
pdf_not_valid() {
	local -r FILE="${1}"
	local -ri CODE=29
	local -r MSG="file \"${FILE}\" is not a valid PDF file." 
	error ${CODE} "${MSG}"
}

error() {
	local -r CODE=$1
	local -r MSG="$2"
	printf "[ERROR %i] %s\n" $CODE "$MSG" >&2
	exit $CODE
}

# warnings
invalid_ranges() {
	local -r INVALID_RANGES="${1}"
	local -r MSG="invalid ranges:
       	${INVALID_RANGES}
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
debug() {
	echo -e "from_page\t${from_page}"
	echo -e "to_page\t\t${to_page}"
	echo -e "IN_PDF_PAGES\t${IN_PDF_PAGES}"
	echo -e "out_pdf\t\t${out_pdf}"
	ls "${OUT_DIR}"
}

# core
iterate_and_split() {
	# a range is valid iff:
	# i. from page (1st col) > 0
	# ii. to page (2nd col) > 0
	# iii. out pdf name (3rd col) != ""
	# iv. from page (1st col) <= to page (2nd col)
	# v. to page (2nd col) <= pdf total pages
	# note: if there are more than 3 cols, then from 3rd col to the last one are used as the out pdf name
	local -r RANGES="${1}"
	local -r IN_PDF="${2}"
	local -ri IN_PDF_PAGES=$( pdfinfo "${IN_PDF}" | grep "Pages:" | cut -d: -f2 )
	local -r OUT_DIR="/tmp/out"
	[ -d "${OUT_DIR}" ] || mkdir "${OUT_DIR}"
	while IFS=, read -r from_page to_page out_pdf
	do
		[ ${from_page} -le ${to_page} ] || ( from_page_gt_to_page ${from_page} ${to_page} && continue )
		[ ${to_page} -le ${IN_PDF_PAGES} ] || ( to_page_gt_in_pdf_pages ${to_page} ${IN_PDF_PAGES} && continue )
		pdftk "${IN_PDF}" cat ${from_page}-${to_page} output "${OUT_DIR}/${out_pdf}.pdf"
		debug
	done <<< "${RANGES}"
}

# entry point
main() {
	local -r IN_PDF="/tmp/in.pdf"
	local -r IN_CSV="/tmp/in.csv"
	pdfinfo "${IN_PDF}" > /dev/null || pdf_not_valid "${IN_PDF}"
	local -r POS_INT_RE="[[:space:]]*[1-9][0-9]*[[:space:]]*"
	local -r NON_EMPTY_STR_RE="[[:space:]]*[^[:space:]].*"
	local -r VALID_RANGE_RE="^${POS_INT_RE},${POS_INT_RE},${NON_EMPTY_STR_RE}$"
	local -r VALID_RANGES="$( grep "${VALID_RANGE_RE}" "${IN_CSV}" )"
	[ -z "${VALID_RANGES}" ] || iterate_and_split "${VALID_RANGES}" "${IN_PDF}"
	local -r INVALID_RANGES="$( grep -v "${VALID_RANGE_RE}" "${IN_CSV}" )"
	[ -z "${INVALID_RANGES}" ] || invalid_ranges "${INVALID_RANGES}"
}

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
main
