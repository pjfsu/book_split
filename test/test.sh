#!/bin/bash

test_inputs_length_not_valid() {
	local -ri expected_exit=11
	printf "[TEST] testing parameters length is not valid...\n"
	bash split_pdf.sh
	[ ${expected_exit} -eq ${?} ] || exit 1
}

test_input_not_found() {
	local -ri expected_exit=13
	printf "[TEST] testing PDF file doesn't exist ...\n"
	bash split_pdf.sh "" "doc/example/ranges.csv"
	printf "[TEST] testing CSV files doesn't exist ...\n"
	bash split_pdf.sh "doc/example/book.pdf" ""
	[ ${expected_exit} -eq ${?} ] || exit 1
}

test_pdf_is_not_valid() {
	local -ri expected_exit=17
	printf "[TEST] testing PDF file is not valid ...\n"
	# sed 's/trailer/%%trailer/' valid.pdf > invalid.pdf
	bash split_pdf.sh "test/invalid.pdf" "doc/example/ranges.csv"
	[ ${expected_exit} -eq ${?} ] || exit 1
}

main() {
	pushd ..
	test_inputs_length_not_valid
	test_input_not_found
	test_pdf_is_not_valid
	printf "[INFO] Everything has failed as expected =D\n"
	popd
}

main
