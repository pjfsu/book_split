#!/bin/bash
# split_book.sh - A script to split PDF books into chapters based on a CSV file. 
# author - Pedro Sánchez Uscamaita
# year - 2024
# repository - github.com/pjfsu/split_book

# This program is free software: you can redistribute it and/or modify 
# it under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# (at your option) any later version. 
# This program is distributed in the hope that it will be useful, 
# but WITHOUT ANY WARRANTY; without even the implied warranty of 
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
# GNU General Public License for more details. 
# You should have received a copy of the GNU General Public License # along with this program. If not, see <http://www.gnu.org/licenses/>.

# Globals
readonly INPUTS_LEN=2
readonly INPUTS_LEN_NOT_VALID_ERR_CODE=11
readonly INPUT_NOT_FOUND_ERR_CODE=13
readonly PDF_NOT_VALID_ERR_CODE=17
readonly INPUTS_LEN_NOT_VALID_ERR_MSG="usage: \"./split_book.sh pdf csv\""
readonly INPUT_NOT_FOUND_ERR_MSG="input not found" 
readonly PDF_NOT_VALID_ERR_MSG="pdf not valid" 

# Validators
validate_inputs() {
	# Description
	#	Validates the inputs parameters provided by the user. 
	#	It ensures the correct number of parameters is provided,
	#	checks if the provided files exist, and
	#	verifies if the PDF file is valid.
	# Globals
	#	none
	# Parameters
	#	$1 - The PDF file to be split.
	validate_input_len $#
	validate_inputs_exist "$@"
	validate_pdf "$1"
}

validate_input_len() {
	# Description
	#	Checks if the number of input parameters provided by the user is valid.
	#	If the number of parameters is not equal to the expected length,
	#	it triggers an error and exists the script.
	# Globals
	#	INPUTS_LEN - The expected number of input parameters provided by the user.
	#	INPUTS_LEN_NOT_VALID_ERR_CODE - Error code for invalid number of inputs.
	#	INPUTS_LEN_NOT_VALID_ERR_MSG - Error message for invalid number of inputs.
	# Parameters
	# 	$1 - The number of input parameters provided by the user
	[ $1 -eq ${INPUTS_LEN} ] || err ${INPUTS_LEN_NOT_VALID_ERR_CODE} "${INPUTS_LEN_NOT_VALID_ERR_MSG}"
}

validate_inputs_exist() {
	# Description
	# 	Check if the inputs files provided by the user exist.
	#	If any of it doesn't exist, 
	#	it triggers an error and exits the script.
	# Globals
	#	INPUT_NOT_FOUND_ERR_CODE - Error code for file not found.
	#	INPUT_NOT_FOUND_ERR_MSG - Error message for file not found.
	# Parameters
	# 	none	
	for input in "$@"; do
		[ -f "${input}" ] || err ${INPUT_NOT_FOUND_ERR_CODE} "${INPUT_NOT_FOUND_ERR_MSG}"
	done
}

validate_pdf() {
	# Description
	#	Checks if the PDF file provided by the user is valid by using the pdfinfo command.
	#	If the PDF file is not valid, 
	#	it triggers an error and exits the script.
	# Globals
	#	PDF_NOT_VALID_ERR_CODE - Error code for invalid PDF file.
	#	PDF_NOT_VALID_ERR_MSG - Error message for invalid PDF file.
	# Parameters
	#	$1 - The PDF file to validated
	pdfinfo "$1" > /dev/null || err ${PDF_NOT_VALID_ERR_CODE} "${PDF_NOT_VALID_ERR_MSG}"
}

# Utils
split() {
	# Description
	#	Splits the PDF file into separate chapters based on the ranges specified in the CSV file.
	#	It creates an output directory if it doesn't exist, then
	#	iterates through the CSV file and splits the PDF file into separate PDF files, 
	#	saving them in the output directory.
	# Globals
	#	none
	# Parameters
	#	$1 - The PDF file to be split.
	#	$2 - The CSV file containing the chapter ranges.
	local -ri pages_num=$(pdfinfo "$1" | awk '/Pages:/ {print $2}')
	local -r out_dir="${1%.pdf}" # removes the ".pdf" extension
	[ ! -d "${out_dir}" ] && mkdir -p "${out_dir}"
	get_chapters ${pages_num} "$2" | while IFS=, read -r from to name; do
		pdftk "$1" cat ${from}-${to} output "${out_dir}/${name}.pdf"
	done
}

get_chapters() {
	# Description
	#	Retrieves valid rows from the CSV file containing chapter ranges. 
	#	A row is considered valid if:
	#	i. The first column is a positive interger representing the starting page number.
	#	ii. The second column is a positive interger representing the ending page number.
	#	iii. The third column is a non-empty string representing the chapter name.
	#	NOTE: If a row matches the criteria and has more than three columns, 
	#	the remaining columns are considered as part of the chapter name.
	# Globals
	#	none
	# Parameters
	#	$1 - The total number of pages in the PDF file.
	#	$2 - The CSV file containing the chapters ranges.
	awk -F, -v pages_num=$1 '\
		/^[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[^[:space:]].*$/ \
		&& $1 <= $2 \
		&& $2 <= pages_num \
		{print $0}' \
		"$2"
}

error() {
	# Description
	#	Prints an error message to standard error and exits the script.
	# Globals
	#	none
	# Parameters
	#	$1 - The error code.
	#	$2 - The error message.
	printf "[ERROR %i] %s\n" $1 "$2" >&2
	exit $1
}

# Entry point
main() {
	# Description
	#	Entry point of the script. It starts by validating the input parameters (PDF and CSV files),
	#	then proceeds to split the PDF file based on the chapter ranges provided in the CSV file.
	# Globals
	# 	none
	# Parameters
	#	$1 - the PDF file to be split
	#	$2 - the CSV file containing the chapter ranges
	validate_inputs "$@"
	split "$1" "$2"
}

main "${@}"
