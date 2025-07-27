# split-pdf-bookmarks

Extract bookmarks from PDFs and split documents into chapters using a companion CSV—served as a FastAPI web service and shipped as a Podman/Docker container.

## Features

- **Bookmark Export**  
  Parse PDF outlines and generate per-level CSV files containing start/end page ranges.

- **PDF Splitting**  
  Accept a CSV with `split,name,from,to` and split the original PDF into multiple fragments.

- **Containerized API**  
  Lightweight container runs a FastAPI app on port `8080`.

- **CLI Client (Bash)**  
  Includes a script to upload PDFs, retrieve ZIPs, and save results to a dedicated per-file directory.

## Project Layout

```
split-pdf-bookmarks/
├── app/                     # FastAPI application
│   ├── main.py              # Entry point
│   ├── routers/             # Endpoints: /api/bookmarks/zip and /api/split
│   └── services/            # Core logic for bookmark extraction and PDF splitting
├── podman/                  # Containerfile and entrypoint
├── split-pdf-bookmarks.sh   # Bash client for API
├── requirements.txt         # Python dependencies
├── LICENSE
└── README.md
```

## Example Workflow

### 1. Start the container

```bash
podman run -d -p <FREE_PORT>:8080 docker.io/pjfsu/split-pdf-bookmarks:latest
```

### 2. Export bookmarks

```bash
split-pdf-bookmarks "Effective DevOps.pdf"
# Output saved to ./Effective DevOps/bookmarks.zip
# Contents: bookmarks_level_0.csv, bookmarks_level_1.csv, ...
```

### 3. Edit CSV to select chapters

Set `"split"` to `"y"` for the entries you want to extract:

```csv
"split","name","from","to"
"y","Chapter 1. The Big Picture",33,42
"y","Chapter 2. What Is Devops?",43,48
...
```

### 4. Split into chapters

```bash
split-pdf-bookmarks "Effective DevOps.pdf" "Effective DevOps/bookmarks_level_1.csv"
# Output saved to ./Effective DevOps/pdfs.zip
# Extracts: Chapter 1.pdf, Chapter 2.pdf, ...
```

## API Reference

### `/api/bookmarks/zip`  
**POST** a `pdf` → returns ZIP of per-level bookmarks in CSV.

### `/api/split`  
**POST** a `pdf` + `csvfile` → returns ZIP of PDF fragments.

## CSV Format for Splitting

```csv
split,name,from,to
```

- `split`: `"y"` means the row will be used
- `name`: filename for the chapter
- `from`, `to`: start/end page (inclusive)

## Bash Client

Use `split-pdf-bookmarks.sh` to send requests locally:

- Automatically detects running container
- Determines endpoint based on arguments
- Creates a dedicated output folder named after the input PDF

Usage:
```bash
./split-pdf-bookmarks.sh book.pdf              # Export bookmarks
./split-pdf-bookmarks.sh book.pdf bookmarks.csv # Split PDF
```

## Container Build (GitHub Actions)

This project uses GitHub CI to:

- Build & tag container image (`podman/Containerfile`)
- Push to Docker Hub (`pjfsu/split-pdf-bookmarks:latest`)
- Triggered on `build` branch push

See `.github/workflows/build_push.yml` for details.

## License

GPLv3 License. See [LICENSE](./LICENSE) for terms.

## Future Ideas

- Web UI front-end for preview and interaction

