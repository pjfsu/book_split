# split_book.sh exit codes tests

fail_because_args_length_is_not_two()
{
	local -ri EXPECTED_EXIT=11

	printf '[TEST] failing because arguments length is not two ...\n'
	bash split_book.sh
	[ ${EXPECTED_EXIT} -eq ${?} ] \
		&& return 0

	return 1
}

fail_because_book_not_exist()
{
	local -ri EXPECTED_EXIT=13

	printf '[TEST] failing because book not exist ...\n'
	bash split_book.sh "" "example/lorem_chapters.xml"
	[ ${EXPECTED_EXIT} -eq ${?} ] \
		&& return 0

	return 1
}

fail_because_chapters_not_exist()
{
	local -ri EXPECTED_EXIT=17

	printf '[TEST] failing because chapters not exist ...\n'
	bash split_book.sh "example/lorem_book.pdf" ""
	[ ${EXPECTED_EXIT} -eq ${?} ] \
		&& return 0

	return 1
}

fail_because_book_is_not_valid()
{
	local -ri EXPECTED_EXIT=19

	printf '[TEST] failing because book is not valid ...\n'
	# sed 's/trailer/%%trailer/' example/lorem_book.pdf > test/invalid_book.pdf
	bash split_book.sh "test/invalid_book.pdf" "example/lorem_chapters.xml"
	[ ${EXPECTED_EXIT} -eq ${?} ] \
		&& return 0

	return 1
}

fail_because_chapters_is_not_valid()
{
	local -ri EXPECTED_EXIT=23
	
	for xml in test/*.xml
	do
		printf '[TEST] failing because chapters "%s" is not valid ...\n' "${xml}"
		bash split_book.sh "example/lorem_book.pdf" "${xml}" > /dev/null
		[ ${EXPECTED_EXIT} -ne ${?} ] \
			&& return 1
		cat /tmp/split_book.error.log
	done

	return 0
}

main()
{
	pushd ..
	fail_because_args_length_is_not_two \
	&& fail_because_book_not_exist \
	&& fail_because_chapters_not_exist \
	&& fail_because_book_is_not_valid \
	&& fail_because_chapters_is_not_valid \
		&& printf "[TEST] everything has failed as expected =D\n"
	popd
}

main
