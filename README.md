# split_pdf

## A Bash script to locally split PDF files based on page ranges specified in a CSV file.

## Index

* [Motivation](#motivation)
* [Overview](#overview)
* [Example](#example)
* [Ranges CSV](#ranges-csv)
* [Exit Codes](#exit-codes)
* [Dependencies](#dependencies)
* [License](#license)

### Motivation

The primary motivation behind this project stems from the need to process PDF documents **locally**, prioritizing data security and confidentiality. Many online tools, such as iLovePDF, require uploading documents to external servers, which introduces potential risks of unauthorized access, data breaches, and non-compliance with security standards.

This project aligns with **information classification principles**, ensuring that sensitive data remains protected at all times. By handling files locally, this solution supports the secure management of data classified as **confidential or restricted** under ISO 27001 standards, which emphasize the importance of preserving confidentiality, integrity, and availability of information.

## Overview

| Name | Description |
|---|---|
| **app\.sh** | The script executed inside the podman container to perform the PDF splitting operation based on the provided CSV file. |
| **Dockerfile** | Defines the podman container environment for secure and portable execution of the splitting process. |
| **LICENSE** | The GNU General Public License Version 3. |
| **README\.md** | This file. |
| **split_pdf\.sh** | The entry point script that handles arguments and ensures the necessary preconditions are met before calling the `podman run` command. |
| **test/** | Contains a single script for validating exit codes and ensuring proper functionality of the tool. |

## Example

```console
user@debian:~/Downloads$ git clone https://github.com/pjfsu/split_pdf.git
Cloning into 'split_pdf'...
remote: Enumerating objects: 4949, done.
remote: Counting objects: 100% (211/211), done.
remote: Compressing objects: 100% (129/129), done.
remote: Total 4949 (delta 103), reused 176 (delta 73), pack-reused 4738 (from 1)
Receiving objects: 100% (4949/4949), 30.45 MiB | 8.61 MiB/s, done.
Resolving deltas: 100% (3324/3324), done.
user@debian:~/Downloads$ ls
split_pdf
user@debian:~/Downloads$ cd split_pdf/
user@debian:~/Downloads/split_pdf$ ls
app.sh  Dockerfile  example  LICENSE  README.md  split_pdf.sh  test
user@debian:~/Downloads/split_pdf$ chmod u+x split_pdf.sh 
user@debian:~/Downloads/split_pdf$ ln -s "$(realpath split_pdf.sh)" ~/.local/bin/split_pdf
user@debian:~/Downloads/split_pdf$ cd ~/Documents/books
user@debian:~/Documents/books$ ls effective-devops_jennifer-davis_ryn-daniels.*
effective-devops_jennifer-davis_ryn-daniels.csv  effective-devops_jennifer-davis_ryn-daniels.pdf
user@debian:~/Documents/books$ cat effective-devops_jennifer-davis_ryn-daniels.csv 
33,42,Chapter 1. The Big Picture
43,48,Chapter 2. What Is Devops?
49,60,Chapter 3. A History of Devops
61,74,Chapter 4. Foundational Terminology and Concepts
75,86,Chapter 5. Devops Misconceptions and Anti-Patterns
87,90,Chapter 6. The Four Pillars of Effective Devops
207,222,Chapter 11. Tools: Ecosystem Overview
223,258,Chapter 12. Tools: Accelerators of Culture
259,264,Chapter 13. Tools: Misconceptions and Troubleshooting
user@debian:~/Documents/books$ echo $PATH | rev | cut -d: -f1 | rev
/home/user/.local/bin
user@debian:~/Documents/books$ ls -l ~/.local/bin/split_pdf 
lrwxrwxrwx 1 user user 43 Apr  6 16:24 /home/user/.local/bin/split_pdf -> /home/user/Downloads/split_pdf/split_pdf.sh
user@debian:~/Documents/books$ split_pdf effective-devops_jennifer-davis_ryn-daniels.{pdf,csv}
...
user@debian:~/Documents/books$ ls effective-devops_jennifer-davis_ryn-daniels*
effective-devops_jennifer-davis_ryn-daniels.csv  effective-devops_jennifer-davis_ryn-daniels.pdf

effective-devops_jennifer-davis_ryn-daniels:
'Chapter 11. Tools: Ecosystem Overview.pdf'                  'Chapter 1. The Big Picture.pdf'      'Chapter 4. Foundational Terminology and Concepts.pdf'
'Chapter 12. Tools: Accelerators of Culture.pdf'             'Chapter 2. What Is Devops?.pdf'      'Chapter 5. Devops Misconceptions and Anti-Patterns.pdf'
'Chapter 13. Tools: Misconceptions and Troubleshooting.pdf'  'Chapter 3. A History of Devops.pdf'  'Chapter 6. The Four Pillars of Effective Devops.pdf'
```

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
|podman|Simple management tool for pods, containers and images|4.3|`apt install podman`
|printf|Format and print data|9.1|`apt install coreutils`
|mkdir|Make directories|9.1|`apt install coreutils`
|dirname|Strip last component from file name|9.1|`apt install coreutils`

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## EOR (End Of Repository)

### I hope this program is useful to you. Thank you very much for visiting this repository!
### Espero que este programa te sea útil. Muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade. Moitas grazas por visitar este repositorio!
