# split_pdf

## A Bash script to locally split PDF files based on page ranges specified in a CSV file.

## Index

* [Motivation](#motivation)
* [Overview](#overview)
* [Example](#example)
* [Ranges CSV](#ranges-csv)
* [Dependencies](#dependencies)
* [Exit Codes](#exit-codes)
* [License](#license)

## Motivation

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

### Clone the Repository

```console
user@debian:~/Downloads$ git clone https://github.com/pjfsu/split_pdf.git
Cloning into 'split_pdf'...
remote: Enumerating objects: 4949, done.
Receiving objects: 100% (4949/4949), 30.45 MiB | 8.61 MiB/s, done.
Resolving deltas: 100% (3324/3324), done.
```

### Navigate and Setup

```console
user@debian:~/Downloads$ cd split_pdf/
user@debian:~/Downloads/split_pdf$ chmod u+x split_pdf.sh 
user@debian:~/Downloads/split_pdf$ ln -s "$(realpath split_pdf.sh)" ~/.local/bin/split_pdf
```

### Prepare Input Files

Ensure the directory contains both the source PDF file and the CSV file with ranges:

```console
user@debian:~/Documents/books$ ls effective-devops_jennifer-davis_ryn-daniels.*
effective-devops_jennifer-davis_ryn-daniels.csv  effective-devops_jennifer-davis_ryn-daniels.pdf
```

Verify the content of the CSV file:

```console
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
```

### Execute the Script

Run the `split_pdf.sh` script with the PDF and CSV files:

```console
user@debian:~/Documents/books$ split_pdf effective-devops_jennifer-davis_ryn-daniels.{pdf,csv}
...
```

### Check the Output

Verify that the split PDF files have been generated:

```console
user@debian:~/Documents/books$ ls effective-devops_jennifer-davis_ryn-daniels/
'Chapter 1. The Big Picture.pdf'      'Chapter 4. Foundational Terminology and Concepts.pdf'
'Chapter 2. What Is Devops?.pdf'      'Chapter 5. Devops Misconceptions and Anti-Patterns.pdf'
'Chapter 3. A History of Devops.pdf'  'Chapter 6. The Four Pillars of Effective Devops.pdf'
'Chapter 11. Tools: Ecosystem Overview.pdf'
'Chapter 12. Tools: Accelerators of Culture.pdf'
'Chapter 13. Tools: Misconceptions and Troubleshooting.pdf'
```

## Ranges CSV

The CSV file used for defining ranges must contain the following columns: `FROM`, `TO`, and `NAME`, detailed as follows:
- **`FROM`**: A positive integer representing the starting page number for splitting the PDF.
- **`TO`**: A positive integer representing the ending page number for splitting the PDF.
- **`NAME`**: A non-empty string indicating the name of the output PDF file to be generated.

A row will be processed to split the PDF only if it meets the following conditions:
1. **`FROM` ≤ `TO`**: The starting page number is less than or equal to the ending page number.
2. **`TO` ≤ Total Page Count**: The ending page number does not exceed the total number of pages in the source PDF.

**Note**: If a valid row contains additional columns beyond `FROM`, `TO`, and `NAME`, the extra columns will be concatenated and treated as part of the `NAME` column value.

## Dependencies

| Name    | Description                                | Version | Installation Command      |
|---------|--------------------------------------------|---------|---------------------------|
| podman  | A tool for managing pods, containers, and images efficiently. | 4.3     | `apt install podman`      |
| printf  | Utility for formatting and printing data.  | 9.1     | `apt install coreutils`   |
| mkdir   | Command for creating directories.          | 9.1     | `apt install coreutils`   |
| dirname | Removes the last component from a file path. | 9.1     | `apt install coreutils`   |

## Exit Codes

| Code | Description                                                      |
|------|------------------------------------------------------------------|
| 0    | Operation completed successfully.                               |
| 11   | A required dependency could not be found.                       |
| 13   | The script `split_pdf.sh` was executed without two input files. |
| 17   | Either the PDF or the CSV file is missing or empty.             |
| 19   | Insufficient permissions to read the PDF or CSV file.           |
| 23   | No write permission for the PDF directory.                      |
| 29   | The specified file is not a valid PDF.                          |

## License

This project is licensed under the GNU General Public License v3.0 - see the LICENSE file for details.

## EOR (End Of Repository)

### I hope this program is useful to you. Thank you very much for visiting this repository!
### Espero que este programa te sea útil. Muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade. Moitas grazas por visitar este repositorio!
