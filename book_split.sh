#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail -o errtrace #-o xtrace
IFS=$'\n\t'

readonly HOST_BOOK="$(realpath "${1}")"
readonly HOST_CHAPTERS="$(realpath "${2}")"
readonly HOST_OUT="${HOST_BOOK%.*}" # removes the extension if exists

readonly APP_IN="/app/in"
readonly APP_OUT="/app/out"
readonly APP_BOOK="${APP_IN}/book.pdf"
readonly APP_CHAPTERS="${APP_IN}/chapters.csv"

! [ -d "${HOST_OUT}" ] && mkdir -p "${HOST_OUT}"
chmod u+w "${HOST_OUT}"

podman run --rm \
	--userns=keep-id \
	--user $(id -u):$(id -g) \
	-v "../app/app.sh:/app/app.sh:Z" \
	-v "${HOST_BOOK}:${APP_BOOK}:ro,Z" \
	-v "${HOST_CHAPTERS}:${APP_CHAPTERS}:ro,Z" \
	-v "${HOST_OUT}:${APP_OUT}:Z" \
	docker.io/pjfsu/book_split:latest

# thanks for using this program!
# grazas por usar este programa!
# gracias por usar este programa!
