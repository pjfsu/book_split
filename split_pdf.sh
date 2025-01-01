#!/bin/bash

# Title - split_pdf 
# Description - A Bash script to split a PDF file based on the ranges provided in a CSV file. 
# Author - Pedro Sánchez Uscamaita
# Repository - github.com/pjfsu/split_pdf
# License - GPLv3
# Year - 2024
# City - A Coruña

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

# Config
readonly INPUT_FILES_LENGTH=2

# Guard
validate_input_files() {
	# Description
	#	It validates the input files. It ensures:
	#	i. The correct number of input files is provided.
	#	ii. The PDF and CSV files exist. 
	#	iii. The PDF and CSV files have read permission. 
	#	iv. The PDF file to be split is a valid PDF file.
	#	v The PDF file to be split directory has write permission.
	#	If any condition fails, it triggers an error.
	# Parameters
	#	$# - The input files number
	#	$@ - The input files
	#	$1 - The PDF file to be split.
	[ $# -eq ${INPUT_FILES_LENGTH} ] || unexpected_input_files_length $#
	for file in "$@"; do
		[ -f "${file}" ] || file_not_found "${file}"
		[ -r "${file}" ] || read_permission_not_found "${file}"
	done
	pdfinfo "$1" &> /dev/null || pdf_not_valid "$1"
	[ -w "$(dirname "$1")" ] || write_permission_not_found "$(dirname "$1")"
}

# Utils
split_pdf() {
	# Description
	#	It splits the PDF file into separate PDF files based on the ranges specified in the CSV file.
	#	The new PDF files are saved in an output directory (it is created if it doesn't exist).
	#	The output directory name is the same as the PDF file to be split without the ".pdf" extension.
	# Parameters
	#	$1 - The PDF file to be split.
	#	$2 - The CSV file containing the ranges.
	local -ri pdf_total_pages_number=$(pdfinfo "$1" | awk '/Pages:/ {print $2}')
	local -r out_dir="${1%.pdf}" # removes the ".pdf" extension
	[ ! -d "${out_dir}" ] && mkdir -p "${out_dir}"
	get_ranges ${pdf_total_pages_number} "$2" | while IFS=, read -r from to name; do
		pdftk "$1" cat ${from}-${to} output "${out_dir}/${name}.pdf"
	done
}

get_ranges() {
	# Description
	#	It retrieves valid rows from the CSV file containing ranges. 
	#	A row is considered valid iff:
	#	i. The first column is a positive integer (representing the starting page number).
	#	ii. The second column is a positive integer (representing the ending page number).
	#	iii. The third column is a non-empty string (representing the PDF file name to generate).
	#	iv. The first column is greater than or equal to the second column.
	#	v. The second column is greater than or equal to the total number of pages in the PDF file to be split.
	#	NOTE: If a row matches the criteria and has more than three columns, 
	#	the remaining columns are considered as part of the new PDF file name.
	# Parameters
	#	$1 - The PDF to be split total pages number.
	#	$2 - The CSV file containing the ranges.
	awk \
		-F, \
		-v pdf_total_pages_number=$1 \
		'/^[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[^[:space:]].*$/ \
		&& $1 <= $2 \
		&& $2 <= pdf_total_pages_number \
		{print $0}' \
		"$2"
}

# Errors

unexpected_input_files_length() {
	# Description
	#	It indicates that the input files length is not valid.
	# Parameters
	#	$1 - The input files length
	local -ri code=11
	local -r message="Expected ${INPUT_FILES_LENGTH} files, given $1. Usage: \"./split_pdf.sh PDF CSV\""
	error ${code} "${message}"
}

file_not_found() {
	# Description
	#	It indicates that the file was not found.
	# Parameters
	#	$1 - The unfound regular file.
	local -ri code=13
	local -r message="The file \"$1\" was not found." 
	error ${code} "${message}"
}

read_permission_not_found() {
	# Description
	#	It indicates that the file has no read permission.
	# Parameters
	#	$1 - The file with no read permission
	local -ri code=17
	local -r message="\"$1\" has no read permission."
	error ${code} "${message}"
}

pdf_not_valid() {
	# Description
	#	It indicates that the PDF file is not a valid PDF file.
	# Parameters
	#	$1 - The invalid PDF file
	local -ri code=19
	local -r message="\"$1\" is not a valid PDF file." 
	error ${code} "${message}"
}

write_permission_not_found() {
	# Description
	#	It indicates that the file has no write permission.
	# Parameters
	# 	$1 - The file with no write permission.
	local -ri code=23
	local -r message="\"$1\" has no write permission."
	error ${code} "${message}"
}

error() {
	# Description
	#	It prints an error message to standard error and exits the script.
	# Parameters
	#	$1 - The error code.
	#	$2 - The error message.
	printf "[ERROR %i] %s\n" $1 "$2" >&2
	exit $1
}

# Entry point
main() {
	# Description
	#	Entry point of the script. It starts by validating the input files,
	#	then proceeds to split the PDF file based on the ranges provided in the CSV file.
	# Parameters
	#	$1 - the PDF file to be split
	#	$2 - the CSV file containing the ranges
	validate_input_files "$@"
	split_pdf "$1" "$2"
}

main "${@}"
