main() {
	local -r IN_PDF="${1}"
	local -r IN_CSV="${2}"
	podman run \
		-d \
		--rm \
		-v "./${IN_PDF}:/tmp/in.pdf" \
		-v "./${IN_CSV}:/tmp/in.csv" \
		-v ".:/tmp/in" \
		localhost/split_pdf
}

main "${@}"
