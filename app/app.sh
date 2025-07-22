#!/usr/bin/env bash
#set -o errexit -o nounset -o pipefail -o errtrace -o xtrace
IFS=$'\n\t'

echo "Validating book" 
if ! pdftk "${BOOK_PDF}" output /dev/null 2>/dev/null; then
	echo "error."
	exit 1
fi
echo "done."

readonly BOOK_PAGES=$(pdftk "${BOOK_PDF}" dump_data | grep "Pages:" | awk '{print $2}')

echo "Validating chapters that match --> pos_int,pos_int,non_empty_str"
grep "${CHAPTER_RE}" "${CHAPTERS_CSV}" | \
while IFS=, read -r from to chapter; do
	echo "Validating --> ${from},${to},${chapter}"
	trim_from="$(tr -d '[:space:]' <<< "${from}")"
	trim_to="$(tr -d '[:space:]' <<< "${to}")"
	trim_chapter="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "${chapter}")"
	if ! [ ${trim_from} -le ${trim_to} -a ${trim_to} -le ${BOOK_PAGES} ]; then
		echo "invalid, remember: 1st col <= 2nd col <= book pages"
		continue
	fi
	echo "done."
	echo "Generating --> ${trim_chapter}.pdf"
	pdftk "${BOOK_PDF}" \
		cat "${trim_from}-${trim_to}" \
		output "${OUT_DIR}/${trim_chapter}.pdf"
	echo "done."
done

echo "Chapters that didn't match --> pos_int,pos_int,non_empty_str"
grep -nv "${CHAPTER_RE}" "${CHAPTERS_CSV}" | sed -E -n 's/^([0-9]+):/line \1 --> /p'

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
