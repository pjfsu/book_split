#!/bin/bash

test_dependencies_not_found() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -ri EXPECTED_EXIT=11

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	(
		# corrupt PATH to simulate missing dependencies
		PATH=""
		"${SPLIT_PDF}" "${PDF}" "${CSV}"
		[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"
	)

	[ ${?} -eq 0 ] && pass "${THIS_TEST_NAME}"
}

test_inputs_length_not_valid() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -ri EXPECTED_EXIT=13

	# test with no inputs
	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	bash "${SPLIT_PDF}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	# test with only the PDF provided
	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	bash "${SPLIT_PDF}" "${PDF}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	# test with only the CSV provided
	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	bash "${SPLIT_PDF}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	pass "${THIS_TEST_NAME}"
}

test_file_not_found_or_empty() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -r EMPTY=""
	local -ri EXPECTED_EXIT=17

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	bash "${SPLIT_PDF}" "${EMPTY}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	bash "${SPLIT_PDF}" "${PDF}" "${EMPTY}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	pass "${THIS_TEST_NAME}"
}

test_read_permission_not_found() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -ri EXPECTED_EXIT=19

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	chmod u-r "${PDF}"
	bash "${SPLIT_PDF}" "${PDF}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"
	chmod u+r "${PDF}"

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	chmod u-r "${CSV}"
	bash "${SPLIT_PDF}" "${PDF}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"
	chmod u+r "${CSV}"

	pass "${THIS_TEST_NAME}"
}

test_write_permission_not_found() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -ri EXPECTED_EXIT=23

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	chmod u-w "$(dirname "${PDF}")"
	bash "${SPLIT_PDF}" "${PDF}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"
	chmod u+w "$(dirname "${PDF}")"

	pass "${THIS_TEST_NAME}"
}

test_pdf_not_valid() {
	local -r THIS_TEST_NAME="${FUNCNAME[0]}"
	local -ri EXPECTED_EXIT=29
	local -r INVALID_PDF="invalid.pdf"

	testing "${THIS_TEST_NAME}" ${EXPECTED_EXIT}
	# sed 's/trailer/%%trailer/' valid.pdf > invalid.pdf
	bash "${SPLIT_PDF}" "${INVALID_PDF}" "${CSV}"
	[ ${EXPECTED_EXIT} -eq ${?} ] || fail "${THIS_TEST_NAME}"

	pass "${THIS_TEST_NAME}"
}

testing() {
	local -r TEST_NAME="${1}"
	local -ri EXPECTED_EXIT=${2}
	printf "[TEST] ${TEST_NAME} - Stating (Expected Exit Code: ${EXPECTED_EXIT}) ...\n"
}

pass() {
	local -r TEST_NAME="${1}"
	printf "[PASS] ${TEST_NAME}\n\n"
}

fail() {
	local -r TEST_NAME="${1}"
	printf "[FAIL] ${TEST_NAME}\n"
	exit 1
}

error() {
	local -r FILE="${1}"
	printf "[ERROR] Test file not found. Ensure file ${FILE} exists.\n"
	exit 1
}

main() {
	local -r SPLIT_PDF="../split_pdf.sh"
	local -r PDF="valid.pdf"
	local -r CSV="valid.csv"

	[ -f "${SPLIT_PDF}" ] || error "${PDF}"
	[ -f "${PDF}" ] || error "${PDF}"
	[ -f "${CSV}" ] || error "${CSV}"

	test_dependencies_not_found
	test_inputs_length_not_valid
	test_file_not_found_or_empty
	test_read_permission_not_found
	test_write_permission_not_found
	test_pdf_not_valid

	printf "[INFO] Everything has failed as expected =D\n"
}

main
