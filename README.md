# split_pdf

## A Bash script to split a PDF based on the ranges provided in a CSV file. 

## Index

* [Motivation](#motivation)
* [Overview](#overview)
* [Example](#example)
* [Ranges CSV](#ranges-csv)
* [Exit Codes](#exit-codes)
* [Dependencies](#dependencies)
* [License](#license)

## Motivation

Splitting a PDF file using online tools (e.g., iLovePDF) can be time-consuming if the PDF file is large (e.g., 100 MB) and the internet speeds are slow. This script allows you to split a PDF offline, saving time and bandwidth.

## Overview

|Name|Description|
|---|---|
|doc/|Contains the pseudocode and an example|
|LICENSE|The GNU General Public License Version 3|
|README\.md|This file|
|split_pdf\.sh|Entry point script|
|test/|Contains a script to test all exit codes|

## Example

```console
user@debian:~/Documents/programs/split_pdf$ ls
doc  LICENSE  README.md  split_pdf.sh  test
user@debian:~/Documents/programs/split_pdf$ cd doc/
user@debian:~/Documents/programs/split_pdf/doc$ ls
example  pseudocode.txt
user@debian:~/Documents/programs/split_pdf/doc$ cd example/
user@debian:~/Documents/programs/split_pdf/doc/example$ ls
lorem.ms  lorem.pdf  ranges.csv
user@debian:~/Documents/programs/split_pdf/doc/example$ cat ranges.csv 
1,2,Chapter 1
3,8,Chapter 2
9,16,Chapter 3
user@debian:~/Documents/programs/split_pdf/doc/example$ bash ../../split_pdf.sh lorem.pdf ranges.csv 
user@debian:~/Documents/programs/split_pdf/doc/example$ ls
lorem  lorem.ms  lorem.pdf  ranges.csv
user@debian:~/Documents/programs/split_pdf/doc/example$ ls lorem
'Chapter 1.pdf'  'Chapter 2.pdf'  'Chapter 3.pdf'
```

__NOTE:__ You can set the execution permission using `chmod u+x split_pdf.sh` and update the PATH with `export PATH=$PATH:<SCRIPT_PATH>`.

## Ranges CSV

The CSV file containing the ranges has the columns `FROM,TO,NAME` where:
- The first column `FROM` is a positive integer (representing the starting page number to split).
- The second column `TO` is a positive integer (representing the ending page number to split).
- The third column `NAME` is a non-empty string (representing the PDF file name to generate).

A row will be used to split the PDF file iff:
1. `FROM` <= `TO`
2. `TO` <= the total number of pages in the PDF file to be split

__NOTE:__ If a row matches the criteria and has more than three columns, the remaining columns are considered as part of the column `NAME`.

## Exit Codes

|Code|Meaning|
|---|---|
|0|OK|
|11|The script was not launched with two input files|
|13|The PDF or the CSV file was not found|
|17|The PDF or the CSV file has no read permission|
|19|The PDF file to be split is not a valid PDF file|
|23|The directory of the PDF file to be split has no write permission|

## Dependencies

|Name|Description|Version|Installation|
|---|---|---|---|
|pdfinfo|Portable Document Format (PDF) document information extractor|22.12.0-2|`apt install poppler-utils`
|pdftk|A handy tool for manipulating PDF|2.02-5|`apt install pdftk`
|awk|Pattern scanning and text processing language|1.3.4.20200120-3.1|`apt install mawk`
|printf|Format and print data|9.1-1|`apt install coreutils`
|mkdir|Make directories|9.1-1|`apt install coreutils`
|dirname|Strip last component from file name|9.1-1|`apt install coreutils`

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## EOR (End Of Repository)

### I hope this program is useful to you. Thank you very much for visiting this repository!
### Espero que este programa te sea útil. ¡Muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade. Moitas grazas por visitar este repositorio!
