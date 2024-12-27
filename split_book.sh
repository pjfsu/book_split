#!/bin/bash

##########################################
#       A BOOK CHAPTERS SPLITTER         #
##########################################
# author:pjfsu		                 #
# license:GPLv3                          #
# repository:github.com/pjfsu/split_book # 
##########################################

check_args_length_is_two()
{
	# description
	#	it checks if this script arguments length is two
	# arguments
	#	${1}:int, this script arguments length
	# globals
	#	none
	# preconditions
	#	i. ${1} >= 0
	# returns
	#	0, if ${1} == 2
	#	1, other case

	[ ${1} -eq 2 ] \
		&& return 0

	printf '[Error] expected two arguments, usage: "./split_book.sh PDF XML"\n' >&2
	return 1
}

check_book_pdf_exists()
{
	# description
	#	it checks if pdf exists
	# arguments
	#	${1}:str, pdf absolute or relative path
	# globals
	#	none
	# preconditions
	#	none
	# returns
	#	0, if ${1} exists
	#	1, other case

	[ -f "${1}" ] \
		&& return 0

	printf '[Error] not found pdf "%s"\n' "${1}" >&2
	return 1
}

check_chapters_xml_exists()
{
	# description
	#	it checks if chapters xml exists
	# arguments
	#	${1}:str, chapters xml absolute or relative path
	# globals
	#	none
	# preconditions
	#	none
	# returns
	#	0, if ${1} exists
	#	1, other case

	[ -f "${1}" ] \
		&& return 0

	printf '[Error] not found chapters xml "%s"\n' "${1}" >&2
	return 1
}

check_book_pdf_is_a_pdf_file()
{
	# description
	#	it checks if pdf is a valid pdf
	# arguments
	#	${1}:str, pdf absolute or relative path
	# globals
	#	none
	# preconditions
	#	i. ${1} exists
	#	ii. /bin/pdfinfo exists
	# returns
	#	0, if ${1} is a valid pdf
	#	1, other case

	printf '[INFO] validating book "%s" ...\n' "${1}"
	pdfinfo "${1}" \
		&& return 0

	# pdfinfo prints its errors to stderr
	return 1
}

generate_config_xml()
{
	# description
	#	it generates config xml
	# arguments
	#	${1}:str, pdf absolute path
	#	${2}:str, chapters xml absolute path
	# globals
	#	CONFIG_XML
	# preconditions
	#	i. ${1} is a valid pdf
	#	ii. ${2} exists
	#	iii. /bin/pdfinfo exists
	# returns
	#	0

	local -ri book_pdf_total_pages=$( pdfinfo "${1}" | grep Pages | cut -d: -f2 )
	local -r outdir="${1%.pdf}"
	local -r chapters_xml_content="$( cat "${2}" )"
	local -r pdfbox_dir="${THIS_SCRIPT_DIR}/pdfbox"
	local -r pdfbox_app_jar="${pdfbox_dir}/pdfbox-app-3.0.3.jar"
	local -r config_xml_template="<!-- BEGIN OF CONFIG XML -->
<split_book 
pdfbox_app_jar=\"${pdfbox_app_jar}\"
outdir=\"%s\">
<book
name=\"%s\"
pages=\"%i\">
<!-- BEGIN OF CHAPTERS XML -->
%s
<!-- END OF CHAPTERS XML -->
</book>
</split_book>
<!-- END OF CONFIG XML -->"

	printf '[INFO] generating xml "%s" ...\n' "${CONFIG_XML}"
	printf "${config_xml_template}\n" \
		"${outdir}" "${1}" ${book_pdf_total_pages} "$( cat "${2}" )" \
		| tee "${CONFIG_XML}"

	return 0
}

validate_config_xml()
{
	# description
	#	it validates config xml against config xsd with apache xerces
	# arguments
	#	none
	# globals
	#	CONFIG_DIR
	#	CONFIG_XML
	# preconditions
	#	i. generated config xml exists
	#	ii. /bin/java exists
	# returns
	#	0, if config xml is valid
	#	1, other case

	local -r config_xsd_="${CONFIG_DIR}/config.xsd"
	local -r xerces_dir="${THIS_SCRIPT_DIR}/xerces/xerces-2_12_2"
	local -r xerces_samples_jar="${xerces_dir}/xercesSamples.jar"
	local -r xerces_impl_jar="${xerces_dir}/xercesImpl.jar"
	local -r error_log="/tmp/split_book.error.log"

	printf '[INFO] validating xml "%s" ...\n' "${CONFIG_XML}"
	# java always returns zero, so java's errors are redirected to a temporary file and to stdout
	# ty! https://stackoverflow.com/questions/692000/how-do-i-write-standard-error-to-a-file-while-using-tee-with-a-pipe
	java -cp "${xerces_samples_jar}:${xerces_impl_jar}" jaxp.SourceValidator \
		-a "${config_xsd_}" \
		-i "${CONFIG_XML}" \
		2> >(tee "${error_log}" >&2)
	[ -s "${error_log}" ] \
		&& return 1

	return 0
}

transform_config_xml_to_pdfbox_script()
{
	# description
	#	it transforms config xml to pdfbox script using config xsl with apache xalan
	# arguments
	#	none
	# globals
	#	CONFIG_XML
	#	PDFBOX_SCRIPT
	# preconditions
	#	i. generated config xml exists
	#	ii. /bin/java exists
	# returns
	#	0

	local -r config_xsl_="${CONFIG_DIR}/config.xsl"
	local -r xalan_dir="${THIS_SCRIPT_DIR}/xalan/xalan-j_2_7_3"
	local -r xalan_jar="${xalan_dir}/xalan.jar"

	printf '[INFO] transforming xml "%s" into script "%s" ...\n' \
		"${CONFIG_XML}" "${PDFBOX_SCRIPT}"
	java -cp "${xalan_jar}" org.apache.xalan.xslt.Process \
		-XSL "${config_xsl_}" \
		-IN "${CONFIG_XML}" \
		-OUT "${PDFBOX_SCRIPT}"
	cat "${PDFBOX_SCRIPT}"

	return 0
}

run_pdfbox_script()
{
	# description
	#	it runs pdfbox script
	# arguments
	#	none
	# globals
	#	PDFBOX_SCRIPT
	# preconditions
	#	i. generated pdfbox script exists
	# returns
	#	0

	printf '[INFO] running script "%s" ...\n' "${PDFBOX_SCRIPT}"
	bash "${PDFBOX_SCRIPT}"

	return 0
}

ty()
{
	# description
	#	it prints a message of thanks in English, Spanish and Galician
	# arguments
	#	none	
	# globals
	# 	none
	# preconditions
	#	none
	# returns
	#	0

	printf '%0.s♥ ' {1..23}
	printf '\n%s\n%s\n%s\n' \
	"Tyvm for using this program!" \
	"Muchas gracias por usar este programa!" \
	"Moitas grazas por usar este programa!"
	printf '%0.s♥ ' {1..23}
	printf '\n'

	return 0
}

main()
{
	# description
	# 	entry point
	# arguments
	#	${1}:str, pdf relative or absolute path
	#	${2}:str, chapters xml relative or absolute path
	# globals
	#	none
	# preconditions
	#	user runs this script
	# returns
	#	0, if ok
	#	11, if arguments length is not two
	#	13, if pdf does not exist
	#	17, if chapters xml does not exist
	#	19, if pdf is not a pdf file
	#	23, if config xml is not well formed (see config.xsd)

	check_args_length_is_two "${#}" || return 11
	check_book_pdf_exists "${1}" || return 13
	check_chapters_xml_exists "${2}" || return 17
	check_book_pdf_is_a_pdf_file "${1}" || return 19

	# at this point, by default, absolute path is used
	local -r THIS_SCRIPT_DIR="$( dirname "$( realpath "${0}" )" )"
	local -r CONFIG_DIR="${THIS_SCRIPT_DIR}/config"
	local -r CONFIG_XML="/tmp/split_book.config.xml"
	local -r PDFBOX_SCRIPT="/tmp/split_book.pdfbox.sh"

	generate_config_xml "$( realpath "${1}" )" "$( realpath "${2}" )"
	validate_config_xml || return 23
	transform_config_xml_to_pdfbox_script
	# un/comment next line to run/debug pdfbox script
	run_pdfbox_script
	ty

	return 0
}

main "${@}"
