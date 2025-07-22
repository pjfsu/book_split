# book_split

A command-line tool that splits a PDF book into individual chapter PDFs based on ranges defined in a CSV file.

## Table of Contents

- [Requirements](#requirements)  
- [Installation](#installation)  
- [Usage](#usage)  
- [Example](#example)  
- [Chapters CSV Format](#chapters-csv-format)  
- [Contributing](#contributing)  
- [License](#license)  

## Requirements

- Bash shell (tested using `5.2`)
- Podman (tested using `5.4`)
- GNU coreutils (tested using `9.5`)

## Installation

1. Clone the repository:  
   ```bash
   git clone https://github.com/pjfsu/book_split.git
   cd book_split
   ```

2. Make the script executable and symlink it:  
   ```bash
   chmod u+x book_split.sh
   [ ! -d ~/.local/bin ] && mkdir -p ~/.local/bin
   [ ! -L ~/.local/bin/book_split ] && ln -s "$(realpath book_split.sh)" ~/.local/bin/book_split
   ```

3. Configure `PATH` and reload your shell: 
   ```bash
   [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
   source ~/.bashrc
   ```

## Usage

```bash
# Splits mybook.pdf into chapters PDFs based on chapters.csv
book_split mybook.pdf chapters.csv
```

## Example

Assume your directory structure is:

```
$HOME/Documents/books/
├── mybook.pdf
└── chapters.csv
```

Contents of `chapters.csv`:

```
1,10,Introduction
11,25,Chapter 1 - Getting Started
26,40,Chapter 2 – Deep Dive, Deep Understand
```

Run:

```bash
book_split mybook.pdf chapters.csv
```

Result:

```
$HOME/Documents/books
├── mybook.pdf
├── chapters.csv
└── mybook/
    ├── Introduction.pdf
    ├── Chapter 1 – Getting Started.pdf
    └── Chapter 2 – Deep Dive, Deep Understand.pdf
```

## Chapters CSV Format

```
start_page,end_page,chapter_name
```

|Column|Type|Description|
|---|---|---|
|`start_page`|positive int|First page of the chapter|
|`end_page`|positive int|Last page of the chapter (≥ start\_page, ≤ total pages)|
|`chapter_name`|non-empty string|Chapter title, if commas appear, all extra columns join it|

_Rows failing validation are reported but skipped._

## Contributing

Contributions and bug reports are welcome:

1. Fork the repository.  
2. Create a branch: `git checkout -b feature/my-feature`.  
3. Commit your changes: `git commit -m "Add my feature"`.  
4. Push and open a Pull Request.  

## License

This project is licensed under the GPLv3 License.  
See [LICENSE](LICENSE) for full details.

## EOR (End Of Repository)

### I hope this program is useful to you. Thank you very much for visiting this repository!
### Espero que este programa te sea útil. Muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade. Moitas grazas por visitar este repositorio!
