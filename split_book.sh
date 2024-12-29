#!/bin/bash
set -e # exit immediately if a command exits with a non-zero status

### CONFIGURATION ###
readonly ARGS_LEN=2

# DIRECTORIES
readonly THIS_SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly XML_DIR="${THIS_SCRIPT_DIR}/xml"

# XML FILES
readonly BOOK_INFO_XSD="${XML_DIR}/book_info.xsd"
readonly BOOK_INFO_XSL="${XML_DIR}/book_info.xsl"

# TEMPORARY FILES
readonly BOOK_INFO_XML="$(mktemp)"
readonly CHAPS_CSV="$(mktemp)"

# ERROR CODES
readonly ARGS_LEN_NOT_VALID_ERR_CODE=11
readonly BOOK_PDF_NOT_VALID_ERR_CODE=13
readonly BOOK_INFO_XML_NOT_VALID_ERR_CODE=17
readonly BOOK_PDF_NOT_FOUND_ERR_CODE=19
readonly CHAPS_XML_NOT_FOUND_ERR_CODE=23

# ERROR MESSAGES
readonly ARGS_LEN_NOT_VALID_ERR_MSG="usage: \"./split_book.sh book.pdf chapter.xml\""
readonly BOOK_PDF_NOT_VALID_ERR_MSG="not valid book.pdf" 
readonly BOOK_INFO_XML_NOT_VALID_ERR_MSG="not valid book_info.xml"
readonly BOOK_PDF_NOT_FOUND_ERR_MSG="not found book.pdf" 
readonly CHAPS_XML_NOT_FOUND_ERR_MSG="not found chapters.xml"

### FUNCTIONS ###
# MAIN FLOW
main() {
	trap cleanup EXIT
	guard "$@"
	split "$1"
	return 0
}

guard() {
	check_args_length_is_valid $#
	check_book_pdf_exists "$1"
	check_chapters_xml_exists "$2"
	check_book_pdf_is_valid "$1"
	check_book_info_xml_is_valid "$1" "$2"
	return 0
}

split() {
	local -r out_dir="${1%.pdf}" # removes the ".pdf" extension
	[ ! -d "${out_dir}" ] && mkdir -p "${out_dir}"
	generate_chapters_csv | while IFS=, read -r from to name; do
		pdftk "$1" cat ${from}-${to} output "${out_dir}/${name}.pdf"
	done
	return 0
}

# CHECKERS
check_args_length_is_valid() {
	[ $1 -eq ${ARGS_LEN} ] || err ${ARGS_LEN_NOT_VALID_ERR_CODE} "${ARGS_LEN_NOT_VALID_ERR_MSG}"
}

check_book_pdf_exists() {
	[ -f "$1" ] || err ${BOOK_PDF_NOT_FOUND_ERR_CODE} "${BOOK_PDF_NOT_FOUND_ERR_MSG}"
}

check_chapters_xml_exists() {
	[ -f "$1" ] || err ${CHAPS_XML_NOT_FOUND_ERR_CODE} "${CHAPS_XML_NOT_FOUND_ERR_MSG}"
}

check_book_pdf_is_valid() {
	pdfinfo "$1" > /dev/null || err ${BOOK_PDF_NOT_VALID_ERR_CODE} "${BOOK_PDF_NOT_VALID_ERR_MSG}"
}

check_book_info_xml_is_valid() {
	generate_book_info_xml "$1" "$2"
	xmllint --quiet --noout --schema "${BOOK_INFO_XSD}" "${BOOK_INFO_XML}" || err ${BOOK_INFO_XML_NOT_VALID_ERR_CODE} "${BOOK_INFO_XML_NOT_VALID_ERR_MSG}"
}

# GENERATORS
generate_book_info_xml() {
	local -ri book_pdf_total_pages=$(pdfinfo "$1" | grep Pages | cut -d: -f2)
	local -r book_info_xml_template="<book pages=\"%i\"><chapters>%s</chapters></book>"
	printf "${book_info_xml_template}\n" ${book_pdf_total_pages} "$(< "$2")" > "${BOOK_INFO_XML}"
	return 0
}

generate_chapters_csv() {
	xsltproc "${BOOK_INFO_XSL}" "${BOOK_INFO_XML}"
	return 0
}

# UTILS
err() {
	printf "[ERROR %i] %s\n" "$1" $2 >&2
	exit $2
}

cleanup() { 
	[ -f "${BOOK_INFO_XML}" ] && rm -f "${BOOK_INFO_XML}" 
	[ -f "${CHAPS_CSV}" ] && rm -f "${CHAPS_CSV}" 
}


### ENTRY POINT ###
main "${@}"
