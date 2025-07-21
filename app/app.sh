#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o errtrace #-o xtrace
IFS=$'\n\t'

DUMP_DATA="$(pdftk ${BOOK} dump_data)"
BOOK_PAGES=$( echo "${DUMP_DATA}" | grep "Pages:" | awk '{print $2}' )
CHAPTERS_ROWS="$( grep "${CHAPTER_RE}" "${CHAPTERS}" )"
INVALID_CHAPTERS="$( grep -nv "${CHAPTER_RE}" "${CHAPTERS}" )"

# a chapter is valid iff:
# 	i. it matchs with 'int,int,str' (see CHAPTER_RE env)
# 	ii. 1st col <= 2nd col
# 	iii. 2nd col <= book pages
if [ -n "${CHAPTERS_ROWS}" ]; then
	while IFS=, read -r from to chapter; do
		echo "Validating chapter '${from},${to},${chapter}' ..."
		if [ ! ${from} -le ${to} ]; then
			echo "1st col is greater than 2nd col"
			continue
		fi
		if [ ! ${to} -le ${BOOK_PAGES} ]; then
			echo "2nd col is greather than book total pages"
			continue
		fi
		echo "Generating chapter '${chapter}.pdf' ..."
		pdftk "${BOOK}" cat ${from}-${to} output "${OUT_DIR}/${chapter}.pdf"
	done <<< "${CHAPTERS_ROWS}"
fi

if [ -n "${INVALID_CHAPTERS}" ]; then
	echo "Invalid chapters:"
	echo "${INVALID_CHAPTERS}" | sed -E -n 's/^([0-9]+):/line \1 --> /p'
	echo "because:"
	echo "I. 1st col is not a positive integer, or"
	echo "II. 2nd col is not a positive integer, or"
	echo "III. 3nd col is an empty string"
fi

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
