# book_split

A command-line tool to split a PDF book into individual chapter PDFs. It reads a CSV file with lines in the format:

```
start_page,end_page,chapter_name
```

and uses a containerized `pdftk` to extract each page range into its own PDF file. Ideal for users who organize their books under `$HOME/Documents/books/` as:

- `book.pdf`           – The full PDF to split  
- `book.csv`           – Chapter definitions  
- `book/`              – Output directory for chapter PDFs  

---

## Table of Contents

- [Features](#features)  
- [Requirements](#requirements)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Example](#example)  
- [Chapters CSV Format](#chapters-csv-format)  
- [Contributing](#contributing)  
- [License](#license)  

---

## Features

- Splits any PDF into per-chapter files  
- Validates page ranges against the book’s total pages  
- Runs in a Docker or Podman container (no local `pdftk` install required)
- Simple CSV syntax for defining chapters  
- Optional helper script for seamless invocation  

---

## Requirements

- Bash shell (for helper script)  
- Docker or Podman  
- GNU `realpath` (commonly preinstalled on Linux/macOS)  

---

## Installation

1. Clone the repository:  
   ```bash
   git clone https://github.com/pjfsu/book_split.git
   cd book_split
   ```

2. Make the helper script executable:  
   ```bash
   chmod u+x book_split.sh
   ```

3. (Optional) Create a symlink in your local bin directory:  
   ```bash
   mkdir -p ~/.local/bin
   ln -s "$(realpath book_split.sh)" ~/.local/bin/book_split
   ```

4. Ensure `~/.local/bin` is in your `PATH` by adding to `~/.bashrc` (or `~/.profile`):  
   ```bash
   export PATH="$PATH:$HOME/.local/bin"
   ```
5. Reload your shell:  
   ```bash
   source ~/.bashrc
   ```

---

## Usage

```bash
book_split /path/to/book.pdf /path/to/chapters.csv
```

- Creates an output folder named after `book.pdf` (without its `.pdf` extension).  
- Generates one PDF per valid CSV row under that output folder.  

Under the hood, the script executes:

```bash
podman run --rm \
  --userns=keep-id \
  --user "$(id -u):$(id -g)" \
  -v "/absolute/path/book.pdf:/app/in/book.pdf:ro,Z" \
  -v "/absolute/path/chapters.csv:/app/in/chapters.csv:ro,Z" \
  -v "/absolute/path/book/:/app/out:Z" \
  docker.io/pjfsu/book_split:latest
```

Replace `podman` with `docker` if preferred.

---

## Example

Assume your directory structure is:

```
$HOME/Documents/books/
├── mybook.pdf
├── mybook.csv
└── mybook/                       # will be created by the script
```

Contents of `mybook.csv`:

```
1,10,Introduction
11,25,Chapter 1 – Getting Started
26,40,Chapter 2 – Deep Dive
```

Run:

```bash
book_split ~/Documents/books/mybook.pdf ~/Documents/books/mybook.csv
```

Result:

```
$HOME/Documents/books/mybook/
├── Introduction.pdf
├── Chapter 1 – Getting Started.pdf
└── Chapter 2 – Deep Dive.pdf
```

---

## Chapters CSV Format

Each line must match:

```
start_page,end_page,chapter_name
```

Rules:

1. `start_page` and `end_page` are positive integers.  
2. `start_page` ≤ `end_page`.  
3. `end_page` ≤ total pages in the book.  
4. `chapter_name` is a non-empty string.  
5. Extra columns (beyond three) are concatenated into `chapter_name`.  

Rows failing validation are reported but skipped.

---

## Contributing

Contributions and bug reports are welcome:

1. Fork the repository.  
2. Create a branch: `git checkout -b feature/my-feature`.  
3. Commit your changes: `git commit -m "Add my feature"`.  
4. Push and open a Pull Request.  

Please follow conventional commit messages and include tests or examples where applicable.

---

## License

This project is licensed under the GPLv3 License.  
See [LICENSE](LICENSE) for full details.

---

## EOR (End Of Repository)

### I hope this program is useful to you. Thank you very much for visiting this repository!
### Espero que este programa te sea útil. Muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade. Moitas grazas por visitar este repositorio!
