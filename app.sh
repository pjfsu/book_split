#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
IFS=$'\n\t'

echo "Validating book ..."
pdfinfo ${BOOK}

BOOK_PAGES=$( pdfinfo "${BOOK}" | grep "Pages:" | cut -d: -f2 )

POS_INT_RE="[[:space:]]*[1-9][0-9]*[[:space:]]*"
NON_EMPTY_STR_RE="[[:space:]]*[^[:space:]].*"
CHAPTER_RE="^${POS_INT_RE},${POS_INT_RE},${NON_EMPTY_STR_RE}$"

WELL_FORMAT_CHAPTERS="$( grep "${CHAPTER_RE}" "${CHAPTERS}" )"
BAD_FORMAT_CHAPTERS="$( grep -nv "${CHAPTER_RE}" "${CHAPTERS}" )"

# a chapter is valid iff:
# 	i. it matchs with CHAPTER_RE
# 	ii. 1st col <= 2nd col
# 	iii. 2nd col <= book pages
if [ -n "${WELL_FORMAT_CHAPTERS}" ]; then
	while IFS=, read -r from to chapter; do
		echo "Validating chapter '${from},${to},${chapter}' ..."
		if [ ! ${from} -le ${to} ]; then
			echo "1st col is greater than 2nd col"
			continue
		fi
		if [ ! ${to} -le ${BOOK_PAGES} ]; then
			echo "the book has '${BOOK_PAGES}' pages, but 2nd col is greater than it"
			continue
		fi
		echo "Generating chapter '${chapter}.pdf' ..."
		pdftk "${BOOK}" cat ${from}-${to} output "${OUT_DIR}/${chapter}.pdf"
	done <<< "${WELL_FORMAT_CHAPTERS}"
fi

if [ -n "${BAD_FORMAT_CHAPTERS}" ]; then
	echo "invalid chapters:"
	echo "${BAD_FORMAT_CHAPTERS}" | sed -E -n 's/^([0-9]+):/line \1\t/p'
	echo "because:"
	echo "I. 1st col is not a positive integer, or"
	echo "II. 2nd col is not a positive integer, or"
	echo "III. 3nd col is an empty string"
fi

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
