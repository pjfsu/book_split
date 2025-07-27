#!/usr/bin/env bash
#
# split-pdf-client.sh
#
# Upload a PDF (and optional CSV) to the split-pdf service running
# in a container. Creates or reuses a per-PDF output directory
# (named after the PDF, minus “.pdf”) and writes the resulting ZIP there.

set -euo pipefail
IFS=$'\n\t'

readonly SCRIPT_NAME=$(basename "$0")
readonly IMAGE="docker.io/pjfsu/split-pdf-bookmarks:latest"
readonly CONTAINER_PORT=8080

# Helper Functions

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <pdf-file> [<bookmarks-csv>]

  <pdf-file>       Path to the PDF to process.
  <bookmarks-csv>  (Optional) CSV with headers: split,name,from,to.
                   If provided, calls POST /api/split;
                   otherwise POST /api/bookmarks/zip.

Output is saved to ./<pdf-basename>/bookmarks.zip or pdfs.zip

Examples:
  # Export bookmarks
  $SCRIPT_NAME book.pdf

  # Split based on CSV ranges
  $SCRIPT_NAME book.pdf ranges.csv
EOF
}

log() {
  printf '[%s] %s\n' "$(date +'%Y-%m-%dT%H:%M:%S')" "$*"
}

error() {
  printf '[%s] ERROR: %s\n' "$(date +'%Y-%m-%dT:%H:%M:%S')" "$*" >&2
  exit 1
}

find_container() {
  local cid
  cid=$(podman ps -q -f "ancestor=${IMAGE}")
  [[ -n "$cid" ]] || error "No running container for image '${IMAGE}'."
  echo "$cid"
}

get_host_port() {
  local cid=$1
  local port
  port=$(podman port "$cid" ${CONTAINER_PORT}/tcp | awk -F: '{print $2}')
  [[ -n "$port" ]] || error "Failed to detect host port for container $cid."
  echo "$port"
}

# Main

main() {
  # 1) Arg parsing
  if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage
    exit 1
  fi

  local pdf_file="$1"
  local csv_file="${2-}"
  local endpoint out_file out_dir

  # 2) Determine & prepare output directory
  out_dir=$(basename "$pdf_file" .pdf)
  if [[ -d "$out_dir" ]]; then
    log "Reusing existing output directory: '$out_dir'"
  else
    log "Creating output directory: '$out_dir'"
    mkdir -p "$out_dir"
  fi

  # 3) Choose endpoint & zip filename
  if [[ -z "$csv_file" ]]; then
    endpoint="/api/bookmarks/zip"
    out_file="${out_dir}/bookmarks.zip"
  else
    endpoint="/api/split"
    out_file="${out_dir}/pdfs.zip"
  fi

  # 4) Input validation
  log "Verifying input files..."
  [[ -r "$pdf_file" ]] || error "Cannot read PDF: $pdf_file"
  if [[ -n "$csv_file" ]]; then
    [[ -r "$csv_file" ]] || error "Cannot read CSV: $csv_file"
  fi

  # 5) Locate container & port
  log "Locating running container..."
  local cid; cid=$(find_container)
  local host_port; host_port=$(get_host_port "$cid")
  log "Server endpoint → http://localhost:${host_port}${endpoint}"

  # 6) Dispatch POST request
  log "Sending request..."
  local curl_args=(-sS --fail --show-error --progress-bar -X POST)
  curl_args+=("-F" "pdf=@${pdf_file}")
  [[ -n "$csv_file" ]] && curl_args+=("-F" "csvfile=@${csv_file}")

  curl "${curl_args[@]}" \
       "http://localhost:${host_port}${endpoint}" \
       -o "${out_file}"

  log "Saved output to '${out_file}'"
}

main "$@"
