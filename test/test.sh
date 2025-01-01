#!/bin/bash

# NOTE: this script uses relative paths.
# Change your directory (cd) to this script directory, 
# other case, it won't work.

readonly SPLIT_PDF="../split_pdf.sh"
readonly EMPTY=""
readonly PDF="../doc/example/lorem.pdf"
readonly CSV="../doc/example/ranges.csv"
readonly INVALID_PDF="invalid.pdf"

test_inputs_length_not_valid() {
	local -ri expected_exit=11
	printf "[TEST] testing unexpected input files length ...\n"
	bash "${SPLIT_PDF}"
	[ ${expected_exit} -eq ${?} ] || exit 1
}

test_file_not_found() {
	local -ri expected_exit=13
	printf "[TEST] testing PDF file to be split doesn't exist ...\n"
	bash "${SPLIT_PDF}" "${EMPTY}" "${CSV}"
	[ ${expected_exit} -eq ${?} ] || exit 1
	printf "[TEST] testing CSV file with ranges doesn't exist ...\n"
	bash "${SPLIT_PDF}" "${PDF}" "${EMPTY}"
	[ ${expected_exit} -eq ${?} ] || exit 1
}

test_read_permission_not_found() {
	local -ri expected_exit=17
	printf "[TEST] testing PDF file to be split has no read permission ...\n"
	chmod u-r "${PDF}"
	bash "${SPLIT_PDF}" "${PDF}" "${CSV}"
	[ ${expected_exit} -eq ${?} ] || exit 1
	chmod u+r "${PDF}"
	printf "[TEST] testing CSV file with ranges has no read permission ...\n"
	chmod u-r "${CSV}"
	bash "${SPLIT_PDF}" "${PDF}" "${CSV}"
	[ ${expected_exit} -eq ${?} ] || exit 1
	chmod u+r "${CSV}"
}

test_pdf_not_valid() {
	local -ri expected_exit=19
	printf "[TEST] testing PDF file to be split is not valid ...\n"
	# sed 's/trailer/%%trailer/' valid.pdf > invalid.pdf
	bash "${SPLIT_PDF}" "${INVALID_PDF}" "${CSV}"
	[ ${expected_exit} -eq ${?} ] || exit 1
}

test_write_permission_not_found() {
	local -ri expected_exit=23
	printf "[TEST] testing PDF file to be split directory has no write permission ...\n"
	chmod u-w "$(dirname "${PDF}")"
	bash "${SPLIT_PDF}"  "${PDF}" "${CSV}"
	[ ${expected_exit} -eq ${?} ] || exit 1
	chmod u+w "$(dirname "${PDF}")"
}

main() {
	test_inputs_length_not_valid
	test_file_not_found
	test_read_permission_not_found
	test_pdf_not_valid
	test_write_permission_not_found
	printf "[INFO] Everything has failed as expected =D\n"
}

main
