#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o errtrace #-o xtrace
IFS=$'\n\t'

readonly BOOK="$(realpath "${1}")"
readonly CHAPTERS="$(realpath "${2}")"
readonly OUT_DIR="${BOOK%.*}"

#readonly APP_IMAGE="localhost/book_split:1.3.3"
readonly APP_IMAGE="docker.io/pjfsu/book_split:latest"

[ ! -d "${OUT_DIR}" ] && mkdir -p "${OUT_DIR}"

podman run --rm \
	--userns=keep-id \
	--user $(id -u):$(id -g) \
	-v "${BOOK}:/app/in/book.pdf:ro,Z" \
	-v "${CHAPTERS}:/app/in/chapters.csv:ro,Z" \
	-v "${OUT_DIR}:/app/out:Z" \
	"${APP_IMAGE}"

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
