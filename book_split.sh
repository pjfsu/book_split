#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o errtrace #-o xtrace
IFS=$'\n\t'

BOOK="$(realpath "${1}")"
CHAPTERS="$(realpath "${2}")"
OUT_DIR="${BOOK%.*}"

PDFTK_CONTAINERFILE="$( find "${HOME}" \
	\( -name '.*' -prune \) \
	-o \
	\( -type f -wholename "*/book_split/pdftk/Containerfile" -print \) 
)"
PDFTK_IMAGE="localhost/pdftk:1.0.0"

APP_CONTAINERFILE="$( find "${HOME}" \
	\( -name '.*' -prune \) \
	-o \
	\( -type f -wholename "*/book_split/app/Containerfile" -print \) 
)"
APP_SCRIPT="$( find "${HOME}" \
	\( -name '.*' -prune \) \
	-o \
	\( -type f -wholename "*/book_split/app/app.sh" -print \) 
)"
APP_IMAGE="localhost/book_split:1.3.3"

[ ! -d "${OUT_DIR}" ] && mkdir -p "${OUT_DIR}"

! podman image exists "${PDFTK_IMAGE}" \
	&& podman build -t "${PDFTK_IMAGE}" -f "${PDFTK_CONTAINERFILE}"

! podman image exists "${APP_IMAGE}" \
	&& podman build -t "${APP_IMAGE}" -f "${APP_CONTAINERFILE}"

podman run --rm \
	--userns=keep-id \
	--user $(id -u):$(id -g) \
	-v "${APP_SCRIPT}:/app/app.sh:ro,Z" \
	-v "${BOOK}:/app/in/book.pdf:ro,Z" \
	-v "${CHAPTERS}:/app/in/chapters.csv:ro,Z" \
	-v "${OUT_DIR}:/app/out:Z" \
	"${APP_IMAGE}"

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
