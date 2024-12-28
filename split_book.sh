#!/bin/bash

##########################################
#       A BOOK CHAPTERS SPLITTER         #
##########################################
# author:pjfsu		                 #
# license:GPLv3                          #
# repository:github.com/pjfsu/split_book # 
##########################################

# GLOBALS
declare -ri ARGS_LENGTH=2
declare -r THIS_SCRIPT_DIR="$( dirname "$( realpath "${0}" )" )"
declare -r TMP_CONFIG_XML="/tmp/split_book.config.xml"
declare -r TMP_VALID_CHAPTERS_CSV="/tmp/split_book.valid_chapters.csv"
declare -r TMP_INVALID_CHAPTERS_CSV="/tmp/split_book.invalid_chapters.csv"

# SETS
set -e # if something fails, then exits

check_args_length()
{
	# description
	#	it checks this script args length
	# arguments
	#	${1}:int, this script args length
	# globals
	#	ARGS_LENGTH
	# preconditions
	#	i. ${1} >= 0
	# returns
	#	0, if ${1} == ARGS_LENGTH
	#	1, other case

	[ ${1} -eq ${ARGS_LENGTH} ] \
		&& return 0

	printf '[Error] expected %i arguments, usage: "./split_book.sh PDF XML"\n' ${ARGS_LENGTH} >&2
	return 1
}

check_pdf_exists()
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

	printf '[Error] not found xml "%s"\n' "${1}" >&2
	return 1
}

check_pdf_is_valid()
{
	# description
	#	it checks if pdf is valid
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

	printf '[INFO] validating pdf "%s" ...\n' "${1}"
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
	#	TMP_CONFIG_XML
	# preconditions
	#	i. ${1} is a valid pdf
	#	ii. ${2} exists
	#	iii. /bin/pdfinfo exists
	# returns
	#	0

	local -ri pdf_total_pages=$( pdfinfo "${1}" | grep Pages | cut -d: -f2 )
	local -r config_xml_template='<split_book>
<book pages="%i">
<chapters>
%s
</chapters>
</book>
</split_book>'

	printf '[INFO] generating config xml "%s" ...\n' "${TMP_CONFIG_XML}"
	printf "${config_xml_template}\n" \
		${pdf_total_pages} "$( cat "${2}" )" \
		| tee "${TMP_CONFIG_XML}"

	return 0
}

validate_config_xml()
{
	# description
	#	it validates config xml against xsd
	# arguments
	#	none
	# globals
	#	THIS_SCRIPT_DIR
	#	TMP_CONFIG_XML
	# preconditions
	#	i. TMP_CONFIG_XML was generated
	#	ii. /bin/xmllint exists
	# returns
	#	0, if config xml is valid
	#	1, other case

	local -r xsd="${THIS_SCRIPT_DIR}/xsd/config.xsd"

	printf '[INFO] validating config xml "%s" against xsd "%s" ...\n' \
		"${TMP_CONFIG_XML}" "${xsd}"
	xmllint --noout --schema "${xsd}" "${TMP_CONFIG_XML}" \
		|| return 1

	return 0
}

transform_config_xml()
{
	# description
	#	it transforms config xml using xslt
	# arguments
	#	none
	# globals
	#	THIS_SCRIPT_DIR
	#	TMP_CONFIG_XML
	#	TMP_VALID_CHAPTERS_CSV
	#	TMP_VALID_CHAPTERS_CSV
	# preconditions
	#	i. TMP_CONFIG_XML was generated
	#	ii. /bin/xsltproc exists
	# returns
	#	0

	local -r xsl_dir="${THIS_SCRIPT_DIR}/xsl"
	local -r valid_chapters_xsl="${xsl_dir}/valid_chapters.xsl"
	local -r invalid_chapters_xsl="${xsl_dir}/invalid_chapters.xsl"

	printf '[INFO] transforming config xml "%s" into csv "%s" ...\n' \
		"${TMP_CONFIG_XML}" "${TMP_VALID_CHAPTERS_CSV}"
	xsltproc "${valid_chapters_xsl}" "${TMP_CONFIG_XML}" \
		| tee "${TMP_VALID_CHAPTERS_CSV}"
	printf '[INFO] transforming config xml "%s" into csv "%s" ...\n' \
		"${TMP_CONFIG_XML}" "${TMP_INVALID_CHAPTERS_CSV}"
	xsltproc "${invalid_chapters_xsl}" "${TMP_CONFIG_XML}" \
		| tee "${TMP_INVALID_CHAPTERS_CSV}"

	return 0
}

split()
{
	# description
	#	it splits the pdf
	# arguments
	#	${1}:str, pdf absolute path
	# globals
	#	TMP_VALID_CHAPTERS_CSV
	#	TMP_VALID_CHAPTERS_CSV
	# preconditions
	#	i. TMP_VALID_CHAPTERS_CSV was generated
	#	ii. TMP_VALID_CHAPTERS_CSV was generated
	#	iii. /bin/pdftk exists
	# returns
	#	0

	local -r outdir="${1%.pdf}" # it removes the ".pdf" extension
	local -i from=0
	local -i to=0
	local chapter=""
	local reason=""

	! [ -d "${outdir}" ] \
		&& printf 'creating directory "%s" ...\n' "${outdir}" \
		&& mkdir "${outdir}"

	while read valid_chapter
	do
		from=$( cut -d, -f1 <<< "${valid_chapter}" )
		to=$( cut -d, -f2 <<< "${valid_chapter}" )
		chapter="$( cut -d, -f3- <<< "${valid_chapter}" )"
		printf '[INFO] splitting chapter "%s" ... ' "${chapter}"
		pdftk "${1}" \
			cat ${from}-${to} \
			output "${outdir}/${chapter}.pdf"
		printf "done!\n"
	done < "${TMP_VALID_CHAPTERS_CSV}"

	while read invalid_chapter
	do
		reason="$( cut -d, -f1 <<< "${invalid_chapter}" )"
		chapter="$( cut -d, -f2- <<< "${invalid_chapter}" )"
		printf '[ERROR] invalid chapter "%s" because "%s"\n' \
			"${chapter}" "${reason}"
	done < "${TMP_INVALID_CHAPTERS_CSV}"

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
	#	ARGS_LENGTH
	#	TMP_CONFIG_XML	
	#	TMP_VALID_CHAPTERS_CSV	
	#	TMP_INVALID_CHAPTERS_CSV	
	# preconditions
	#	user runs this script
	# returns
	#	0, if ok
	#	11, if arguments length is not two
	#	13, if pdf doesn't exist
	#	17, if chapters xml doesn't exist
	#	19, if pdf isn't valid
	#	23, if config xml is not well formed (see config.xsd)

	check_args_length "${#}" || return 11
	check_pdf_exists "${1}" || return 13
	check_chapters_xml_exists "${2}" || return 17
	check_pdf_is_valid "${1}" || return 19
	generate_config_xml "$( realpath "${1}" )" "$( realpath "${2}" )"
	validate_config_xml || return 23
	transform_config_xml
	split "$( realpath "${1}" )"
	ty

	return 0
}

main "${@}"
