#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
IFS=$'\n\t'

readonly BOOK="$(realpath ${1})"
readonly CHAPTERS="$(realpath ${2})"
readonly OUT_DIR="${BOOK%.*}"
readonly CONTAINERFILE="$(find $HOME -type f -wholename "*/book_split/Containerfile" 2> /dev/null)"
readonly BOOK_SPLIT_IMG="localhost/book_split:1.3.3"

[ ! -d "${OUT_DIR}" ] && mkdir -p "${OUT_DIR}"

! podman image exists "${BOOK_SPLIT_IMG}" \
	&& podman build -t "${BOOK_SPLIT_IMG}" -f "${CONTAINERFILE}"

podman run --rm \
	-v "${BOOK}:/app/in/book.pdf:ro,Z" \
	-v "${CHAPTERS}:/app/in/chapters.csv:ro,Z" \
	-v "${OUT_DIR}:/app/out:Z" \
	"${BOOK_SPLIT_IMG}"

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
