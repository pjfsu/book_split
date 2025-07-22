#!/usr/bin/env bash
#set -o errexit -o nounset -o pipefail -o errtrace -o xtrace
IFS=$'\n\t'

echo "Validating book and chapters permissions ..."
if ! [ -r "${BOOK}" -a -r "${CHAPTERS}" ]; then
	echo "error."
	exit 1
fi
echo "done."

echo "Validating book ..."
if ! pdftk "${BOOK}" output /dev/null; then
	echo "error."
	exit 1
fi
echo "done."

readonly BOOK_PAGES=$(pdftk "${BOOK}" dump_data | grep "Pages:" | awk '{print $2}')

echo "Validating chapters that match --> int,int,str"
grep "${CHAPTER_RE}" "${CHAPTERS}" | \
while IFS=, read -r from to chapter; do
	echo "Validating --> ${from},${to},${chapter}"
	trim_from="$(tr -d '[:space:]' <<< "${from}")"
	trim_to="$(tr -d '[:space:]' <<< "${to}")"
	trim_chapter="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<< "${chapter}")"
	if ! [ ${trim_from} -le ${trim_to} -a ${trim_to} -le ${BOOK_PAGES} ]; then
		echo "invalid, remember: 1st col <= 2nd col <= book pages"
		echo "done."
		continue
	fi
	echo "Generating --> ${trim_chapter}.pdf"
	pdftk "${BOOK}" \
		cat "${trim_from}-${trim_to}" \
		output "${OUT_DIR}/${trim_chapter}.pdf"
	echo "done."
done

echo "Chapters that didn't match --> int,int,str"
grep -nv "${CHAPTER_RE}" "${CHAPTERS}" | sed -E -n 's/^([0-9]+):/line \1 --> /p'

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
