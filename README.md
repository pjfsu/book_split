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

### 0. Create a symlink

```bash
ln -s "$(realpath split-pdf-bookmarks.sh)" ~/.local/bin/split-pdf-bookmarks
```

### 1. Start the container

```bash
podman run -d -p 8080:8080 docker.io/pjfsu/split-pdf-bookmarks:latest
```

> You can use another host port (container host is 8080)

### 2. Export bookmarks

```bash
split-pdf-bookmarks "Effective DevOps.pdf"
```

### 3. Unzip bookmarks

```bash
unzip "Effective DevOps"/bookmarks.zip -d "Effective DevOps"/
```

### 4. Edit CSV to select chapters

Set `"split"` to `"y"` for the entries you want to extract:

```csv
vim "Effective DevOps"/bookmarks_level_1.csv
"split","name","from","to"
"n","Introducing Effective Devops",22,22
...
"y","Chapter 1. The Big Picture",33,42
"y","Chapter 2. What Is Devops?",43,48
...
"n","Chapter 20. Further Resources",387,392
```

### 5. Split into chapters

```bash
split-pdf-bookmarks "Effective DevOps.pdf" "Effective DevOps/bookmarks_level_1.csv"
```

### 6. Unzip chapters

```bash
unzip "Effective DevOps"/pdfs.zip -d "Effective DevOps"
ls -1 "Effective DevOps"/Chapter*
'Effective DevOps/Chapter 1. The Big Picture.pdf'
'Effective DevOps/Chapter 2. What Is Devops.pdf'
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

- `split`: `"y"`/`"n"` means the row will/won't be used
- `name`: filename for the generated PDF
- `from`, `to`: start/end page (inclusive)

## Bash Client

Use `split-pdf-bookmarks.sh` to send requests locally:

- Automatically detects running container
- Determines endpoint based on arguments
- Creates a dedicated output folder named after the input PDF

Usage:
```bash
./split-pdf-bookmarks.sh book.pdf               # Export bookmarks
./split-pdf-bookmarks.sh book.pdf bookmarks.csv # Split PDF
```

## License

GPLv3 License. See [LICENSE](./LICENSE) for terms.

## Future Ideas

- Web UI front-end for preview and interaction
