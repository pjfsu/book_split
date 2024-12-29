#!/bin/bash

# Source configuration
source "$(dirname "$(realpath "$0")")/config.sh"

# Main functions
main() {
	# description
	#	entry point
	# globals
	# 	none
	# arguments
	#	$1, the book to split
	trap cleanup EXIT
	guard "$@"
	split "$1"
}

guard() {
	# description
	#	check everything is OK before splitting
	# globals
	#	none
	# arguments
	#	$1, the book to split
	#	$2, the xml with <chapter> tags
	check_args_length_is_valid $#
	check_book_pdf_exists "$1"
	check_chapters_xml_exists "$2"
	check_book_pdf_is_valid "$1"
	check_book_info_xml_is_valid "$1" "$2"
}

split() {
	# description
	#	split the book into chapters
	# globals
	#	none
	# arguments
	#	$1, the book to split
	generate_chapters_csv
	local -r out_dir="${1%.pdf}" # removes the ".pdf" extension
	[ ! -d "${out_dir}" ] && mkdir -p "${out_dir}"
	while IFS=, read -r from to name; do
		pdftk "$1" cat ${from}-${to} output "${out_dir}/${name}.pdf"
	done < "${CHAPS_CSV}"
}

# Checkers
check_args_length_is_valid() {
	# description
	#	check if main() args length is valid
	# globals
	#	ARGS_LEN
	#	ARGS_LEN_NOT_VALID_ERR_CODE
	#	ARGS_LEN_NOT_VALID_ERR_MSG
	# arguments
	# 	$1, main() args length
	[ $1 -eq ${ARGS_LEN} ] || err ${ARGS_LEN_NOT_VALID_ERR_CODE} "${ARGS_LEN_NOT_VALID_ERR_MSG}"
}

check_book_pdf_exists() {
	# description
	# 	check if the book to split exists
	# globals
	#	BOOK_PDF_NOT_FOUND_ERR_CODE
	#	BOOK_PDF_NOT_FOUND_ERR_MSG
	# arguments
	# 	$1, the user book to split
	[ -f "$1" ] || err ${BOOK_PDF_NOT_FOUND_ERR_CODE} "${BOOK_PDF_NOT_FOUND_ERR_MSG}"
}

check_chapters_xml_exists() {
	# description
	#	check if the xml with <chapter> tags exists
	# globals
	#	CHAPS_XML_NOT_FOUND_ERR_CODE
	#	CHAPS_XML_NOT_FOUND_ERR_MSG
	# arguments
	#	$1, the xml with <chapter> tags 
	[ -f "$1" ] || err ${CHAPS_XML_NOT_FOUND_ERR_CODE} "${CHAPS_XML_NOT_FOUND_ERR_MSG}"
}

check_book_pdf_is_valid() {
	# description
	#	check if the book to split is a valid pdf file
	# globals
	#	BOOK_PDF_NOT_VALID_ERR_CODE
	#	BOOK_PDF_NOT_VALID_ERR_MSG
	# arguments
	#	$1, the book to split
	pdfinfo "$1" > /dev/null || err ${BOOK_PDF_NOT_VALID_ERR_CODE} "${BOOK_PDF_NOT_VALID_ERR_MSG}"
}

check_book_info_xml_is_valid() {
	# description
	#	check if the generated xml (BOOK_INFO_XML) is well formed against xsd (BOOK_INFO_XSD)
	#	for more info, see ./xml/book_info.xsd
	# globals
	#	BOOK_INFO_XSD
	#	BOOK_INFO_XML
	#	BOOK_INFO_XML_NOT_VALID_ERR_CODE
	#	BOOK_INFO_XML_NOT_VALID_ERR_MSG
	# arguments
	#	$1, the book to split
	#	$2, the xml with <chapter> tags
	generate_book_info_xml "$1" "$2"
	xmllint --quiet --noout --schema "${BOOK_INFO_XSD}" "${BOOK_INFO_XML}" || err ${BOOK_INFO_XML_NOT_VALID_ERR_CODE} "${BOOK_INFO_XML_NOT_VALID_ERR_MSG}"
}

# Generators
generate_book_info_xml() {
	# description
	# 	generate a temporary xml (BOOK_INFO_XML) with information about the book and the chapters
	# globals
	#	BOOK_INFO_XML
	# arguments
	#	$1, the pdf to split
	#	$2, the xml with <chapter> tags
	local -ri book_pdf_total_pages=$(pdfinfo "$1" | grep Pages | cut -d: -f2)
	local -r book_info_xml_template="<book pages=\"%i\"><chapters>%s</chapters></book>"
	printf "${book_info_xml_template}\n" ${book_pdf_total_pages} "$(< "$2")" > "${BOOK_INFO_XML}"
}

generate_chapters_csv() {
	# description
	#	transform the temporary xml (BOOK_INFO_XML) into a temporary csv (CHAPS_CSV) using a xsl (BOOK_INFO_XSL)
	#	for more info, see ./xml/book_info.xsl
	# globals
	#	CHAPS_CSV
	#	BOOK_INFO_XSL
	#	BOOK_INFO_XML
	# arguments
	#	none
	xsltproc --output "${CHAPS_CSV}" "${BOOK_INFO_XSL}" "${BOOK_INFO_XML}"
}

# Utils
err() {
	# description
	#	print an error and exit the program
	# globals
	#	none
	# arguments
	#	$1, the error code
	#	$2, the error message
	printf "[ERROR %i] %s\n" $1 "$2" >&2
	exit $1
}

cleanup() { 
	# description
	#	remove temporary files after an exit signal
	# globals
	#	BOOK_INFO_XML
	#	CHAPS_CSV
	# arguments
	#	none
	[ -f "${BOOK_INFO_XML}" ] && rm -f "${BOOK_INFO_XML}" 
	[ -f "${CHAPS_CSV}" ] && rm -f "${CHAPS_CSV}" 
}

# Entry point
main "${@}"
