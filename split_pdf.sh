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

# Globals
readonly INPUTS_LENGTH=2
readonly INPUTS_LENGTH_NOT_VALID_ERROR_CODE=11
readonly INPUT_NOT_FOUND_ERROR_CODE=13
readonly PDF_NOT_VALID_ERROR_CODE=17
readonly INPUTS_LENGTH_NOT_VALID_ERROR_MESSAGE="usage: \"./split_pdf.sh PDF CSV\""
readonly INPUT_NOT_FOUND_ERROR_MESSAGE="The PDF file or the CSV file was not found." 
readonly PDF_NOT_VALID_ERROR_MESSAGE="The PDF file to be split is not valid." 

# Validators
validate_inputs() {
	# Description
	#	Validates the script inputs. 
	#	It ensures:
	#	i. the correct number of inputs is provided,
	#	ii. the inputs files exist, and
	#	iii. the PDF file to be split is valid.
	# Globals
	#	none
	# Parameters
	#	$1 - The PDF file to be split.
	validate_input_length $#
	validate_inputs_exist "$@"
	validate_pdf "$1"
}

validate_input_length() {
	# Description
	#	Checks if the number of script inputs is valid.
	#	If the number of script inputs is not equal to the expected length,
	#	it triggers an error and exists the script.
	# Globals
	#	INPUTS_LENGTH - The expected number of script inputs.
	#	INPUTS_LENGTH_NOT_VALID_ERROR_CODE - Error code for invalid number of script inputs.
	#	INPUTS_LENGTH_NOT_VALID_ERROR_MESSAGE - Error message for invalid number of script inputs.
	# Parameters
	# 	$1 - The number of script input. 
	[ $1 -eq ${INPUTS_LENGTH} ] || error ${INPUTS_LENGTH_NOT_VALID_ERROR_CODE} "${INPUTS_LENGTH_NOT_VALID_ERROR_MESSAGE}"
}

validate_inputs_exist() {
	# Description
	# 	Check if the script inputs exist.
	#	If any of it doesn't exist, it triggers an error and exits the script.
	# Globals
	#	INPUT_NOT_FOUND_ERROR_CODE - Error code for script input not found.
	#	INPUT_NOT_FOUND_ERROR_MESSAGE - Error message for script input not found.
	# Parameters
	# 	none	
	for input in "$@"; do
		[ -f "${input}" ] || error ${INPUT_NOT_FOUND_ERROR_CODE} "${INPUT_NOT_FOUND_ERROR_MESSAGE}"
	done
}

validate_pdf() {
	# Description
	#	Checks if the PDF file to be split is valid.
	#	If the PDF file is not valid, it triggers an error and exits the script.
	#	It uses the pdfinfo command.
	# Globals
	#	PDF_NOT_VALID_ERROR_CODE - Error code for invalid PDF file.
	#	PDF_NOT_VALID_ERROR_MESSAGE - Error message for invalid PDF file.
	# Parameters
	#	$1 - The PDF file to be split.
	pdfinfo "$1" &> /dev/null || error ${PDF_NOT_VALID_ERROR_CODE} "${PDF_NOT_VALID_ERROR_MESSAGE}"
}

# Utils
split() {
	# Description
	#	Splits the PDF file into separate PDF files based on the ranges specified in the CSV file.
	#	It saves them in an output directory (it is created if it doesn't exist).
	#	The output directory name is the same as the PDF file to be split without the ".pdf" extension.
	#	It uses the pdftk command.
	# Globals
	#	none
	# Parameters
	#	$1 - The PDF file to be split.
	#	$2 - The CSV file containing the ranges.
	local -ri pdf_total_pages_num=$(pdfinfo "$1" | awk '/Pages:/ {print $2}')
	local -r out_dir="${1%.pdf}" # removes the ".pdf" extension
	[ ! -d "${out_dir}" ] && mkdir -p "${out_dir}"
	get_ranges ${pdf_total_pages_num} "$2" | while IFS=, read -r from to name; do
		pdftk "$1" cat ${from}-${to} output "${out_dir}/${name}.pdf"
	done
}

get_ranges() {
	# Description
	#	Retrieves valid rows from the CSV file containing ranges. 
	#	A row is considered valid if:
	#	i. The first column is a positive interger representing the starting page number.
	#	ii. The second column is a positive interger representing the ending page number.
	#	iii. The third column is a non-empty string representing the new PDF file name.
	#	NOTE: If a row matches the criteria and has more than three columns, 
	#	the remaining columns are considered as part of the new PDF file name.
	# Globals
	#	none
	# Parameters
	#	$1 - The PDF to be split total pages number.
	#	$2 - The CSV file containing the ranges.
	awk -F, -v pdf_total_pages_num=$1 '\
		/^[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[1-9][0-9]*[[:space:]]*,[[:space:]]*[^[:space:]].*$/ \
		&& $1 <= $2 \
		&& $2 <= pdf_total_pages_num \
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
	#	Entry point of the script. It starts by validating the script inputs,
	#	then proceeds to split the PDF file based on the ranges provided in the CSV file.
	# Globals
	# 	none
	# Parameters
	#	$1 - the PDF file to be split
	#	$2 - the CSV file containing the ranges
	validate_inputs "$@"
	split "$1" "$2"
}

main "${@}"
