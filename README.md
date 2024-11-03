# split_book

## _a GNU/Linux x86-64 shell program to split a book into chapters_

## Index

* [Motivation](#motivation)
* [Overview](#overview)
* [Chapters XML](#chapters-xml)
* [Config XSL](#config-xsl)
* [Example](#example)
* [Exit Codes](#exit-codes)
* [Dependencies](#dependencies)
* [License](#license)
* [Comments](#comments)
* [Mistakes](#mistakes-%C2%AF%5C_(%E3%83%84)_%2F%C2%AF)

## Motivation

Sometimes I want to split a book (PDF file) into chapters, but if the book is _large_, 100 MB for example, and the internet upload/download speed is slow, then splitting it online (iLovePDF for example) can be time-consuming.  So I developed this program to split a book offline (using PDFBox) into chapters (defined in a XML file). Graphically:

![diagram.png](./diagram/diagram.png "Diagram")

## Overview

|Name|Description|
|---|---|
|config/|it contains _config_ XSD 1.0 and _config_ XSL 1.0 files|
|diagram/|it contains _Diagram_ PNG file and drawio file (edited using _drawio-desktop_ AppImage, downloaded from https://github.com/jgraph/drawio-desktop/releases)|
|example/|it contains a PDF file with "Lorem ipsum dolor ..." phrases (exported from _example/lorem.odt_ using LibreOffice Writer) and a XML file with chapters (see [_Example_](#example) section)|
|pdfbox/|it contains PDFBox app jar (see [_Dependencies_](#dependencies) section), used to split the book|
|test/|it containts _test/test.sh_ to test all the exit codes of main script _split_book.sh_ (see [_Exit Codes_](#exit-codes) section)|
|xalan/|it contains Xalan jars (see [_Dependencies_](#dependencies) section), used to transform _config.xml_ to _pdfbox\.sh_ using _config.xsl_|
|xerces/|it contains Xerces jars (see [_Dependencies_](#dependencies) section), used to validate _config.xml_ against _config.xsl_|
|README\.md|it is this file (I used _mdview_ AppImage, downloaded from https://github.com/c3er/mdview/releases, to display it while I was editing it)|
|gpl-3.0.txt|it contains the GNU General Public License Version 3 in plain text (downloaded from https://www.gnu.org/licenses/gpl-3.0.txt)|
|split_book.sh|it contains _main()_ function|

## Chapters XML

The chapters XML file given by the user is valid, iff:
1. there is no XML declaration ```<?xml version="1.0" encoding="utf-8"?>```
2. _\<chapters\>_ tag is root
3. _\<chapter>_ tag is root child
4. _\<chapter>_ tag appears at least once
5. _\<chapter>_ tag has 3 non-optional attributes: _from_, _to_ and _name_
6. _from_ attribute is a positive integer
7. _to_ attribute is a positive integer
8. _name_ attribute is a non-empty string

Some invalid chapters XML files (taken from _tests/_ directory):

|Name|Reason|Content|
|---|---|---|
|xml_declaration.xml|there is xml declaration|```<?xml version="1.0" encoding="utf-8"?><chapters><chapter from="1" to="1" name="name"/></chapters>```|
|misspelled_chapters.xml|_\<chapters>_ tag is misspelled|```<shapters><chapter from="1" to="1" name="name"/></shapters>```|
|misspelled_chapter.xml|_\<chapter>_ tag is misspelled|```<chapters><shapter from="1" to="1" name="name"/></chapters>```|
|missing_chapters.xml|_\<chapters>_ tag is missing|```<chapter from="1" to="1" name="name"/>```|
|missing_chapter.xml|_\<chapter>_ tag is missing|```<chapters></chapters>```|
|missing_attr_from.xml|_from_ attribute is missing|```<chapters><chapter to="1" name="name"/></chapters>```|
|missing_attr_to.xml|_to_ attribute is missing|```<chapters><chapter from="1" name="name"/></chapters>```|
|missing_attr_name.xml|_name_ attribute is missing|```<chapters><chapter from="1" to="1"/></chapters>```|
|attr_from_is_not_positive_integer.xml|_from_ attribute value is not a positive integer|```<chapters><chapter from="0" to="1" name="name"/></chapters>```|
|attr_to_is_not_positive_integer.xml|_to_ attribute value is not a positive integer|```<chapters><chapter from="1" to="0" name="name"/></chapters>```|
|attr_name_is_empty.xml|_name_ attribute is a empty string|```<chapters><chapter from="1" to="1" name=""/></chapters>```|

## Config XSL

Config XML file has the next format (see _config/config.xsd_ file for more info):

```
<split_book 
 pdfbox_app_jar="PDFBOX_APP_JAR" 
 outdir="OUTDIR">
<book name="BOOK" pages="PAGES">
<chapters> <!-- given by user -->
<chapter from="FROM" to="TO" name="NAME"/> <!-- minOccurs="1" -->
</chapters>
</book>
</split_book>
```

Where:
1. _PDFBOX_APP_JAR_ is pdfbox-app.jar absolute path
2. _OUTDIR_ is directory where new PDF files will be saved, its name is book PDF file absolute path without extension "_.pdf_"
3. _BOOK_ is book PDF file absolute path
4. _PAGES_ is book PDF file total pages 
5. _FROM_ is the page where the chapter of the book starts.
6. _TO_ is the page where the chapter of the book ends.
7. _NAME_ is the chapter name

For each _\<chapter>_ tag such as _FROM_ <= _TO_ <= _PAGES_, the next command is generated: 

```
printf 'generating "%s.pdf" ... ' "NAME"
java -jar "PDFBOX_APP_JAR" split \
 -startPage=FROM \
 -endPage=TO \
 -i="BOOK" \
 -outPrefix="OUTDIR/NAME"
mv "OUTDIR/NAME-1.pdf" "OUTDIR/NAME.pdf"
printf 'done!\n'
```

__NOTE:__ PDFBox by default appends the string "_-1.pdf_" to _-outputPrefix_ value.

For each _\<chapter>_ tag such as not(_FROM_ <= _TO_ <= _PAGES_), the next command is generated: 

```
printf 'invalid chapter "%s", because from=%i is greater than to=%i or to=%i is greater than pages=%i\n' \
 "NAME" "FROM" "TO" "TO" "PAGES"
```

## Example

The next example was run using Debian 12.

```
user@debian:~/Documents/programs/split_book$ ls example/
lorem_book.odt  lorem_book.pdf  lorem_chapters.xml
user@debian:~/Documents/programs/split_book$ bash split_book.sh example/lorem_book.pdf example/lorem_chapters.xml 
[INFO] validating book "example/lorem_book.pdf" ...
Creator:         Writer
Producer:        LibreOffice 7.4
CreationDate:    Thu Oct 24 19:18:58 2024 CEST
Custom Metadata: no
Metadata Stream: no
Tagged:          no
UserProperties:  no
Suspects:        no
Form:            none
JavaScript:      no
Pages:           3
Encrypted:       no
Page size:       595.304 x 841.89 pts (A4)
Page rot:        0
File size:       25021 bytes
Optimized:       no
PDF version:     1.6
[INFO] generating xml "/tmp/split_book.config.xml" ...
<!-- BEGIN OF CONFIG XML -->
<split_book 
pdfbox_app_jar="/home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar"
outdir="/home/user/Documents/programs/split_book/example/lorem_book">
<book
name="/home/user/Documents/programs/split_book/example/lorem_book.pdf"
pages="3">
<!-- BEGIN OF CHAPTERS XML -->
<chapters>
<chapter from="1" to="1" name="first page"/>
<chapter from="2" to="2" name="second page"/>
<chapter from="3" to="3" name="third page"/>
<chapter from="1" to="2" name="pages from 1 to 2"/>
<chapter from="2" to="3" name="pages from 2 to 3"/>
<chapter from="1" to="3" name="all pages"/>
<chapter from="2" to="1" name="invalid 1"/>
<chapter from="1" to="11" name="invalid 2"/>
<chapter from="7" to="11" name="invalid 3"/>
</chapters>
<!-- END OF CHAPTERS XML -->
</book>
</split_book>
<!-- END OF CONFIG XML -->
[INFO] validating xml "/tmp/split_book.config.xml" ...
/tmp/split_book.config.xml: 10 ms
[INFO] transforming xml "/tmp/split_book.config.xml" into script "/tmp/split_book.pdfbox.sh" ...
# BEGIN OF PDFBOX SCRIPT
printf 'generated pdfs will be saved in "%s"\n' "/home/user/Documents/programs/split_book/example/lorem_book"
! [ -d "/home/user/Documents/programs/split_book/example/lorem_book" ] && mkdir "/home/user/Documents/programs/split_book/example/lorem_book"
# CHAPTER "first page"
printf 'generating "%s.pdf" ... ' "first page"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=1 \
 -endPage=1 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/first page"
mv "/home/user/Documents/programs/split_book/example/lorem_book/first page-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/first page.pdf"
printf 'done!\n'
# CHAPTER "second page"
printf 'generating "%s.pdf" ... ' "second page"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=2 \
 -endPage=2 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/second page"
mv "/home/user/Documents/programs/split_book/example/lorem_book/second page-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/second page.pdf"
printf 'done!\n'
# CHAPTER "third page"
printf 'generating "%s.pdf" ... ' "third page"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=3 \
 -endPage=3 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/third page"
mv "/home/user/Documents/programs/split_book/example/lorem_book/third page-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/third page.pdf"
printf 'done!\n'
# CHAPTER "pages from 1 to 2"
printf 'generating "%s.pdf" ... ' "pages from 1 to 2"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=1 \
 -endPage=2 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/pages from 1 to 2"
mv "/home/user/Documents/programs/split_book/example/lorem_book/pages from 1 to 2-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/pages from 1 to 2.pdf"
printf 'done!\n'
# CHAPTER "pages from 2 to 3"
printf 'generating "%s.pdf" ... ' "pages from 2 to 3"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=2 \
 -endPage=3 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/pages from 2 to 3"
mv "/home/user/Documents/programs/split_book/example/lorem_book/pages from 2 to 3-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/pages from 2 to 3.pdf"
printf 'done!\n'
# CHAPTER "all pages"
printf 'generating "%s.pdf" ... ' "all pages"
java -jar /home/user/Documents/programs/split_book/pdfbox/pdfbox-app-3.0.3.jar split \
 -startPage=1 \
 -endPage=3 \
 -i="/home/user/Documents/programs/split_book/example/lorem_book.pdf" \
 -outputPrefix="/home/user/Documents/programs/split_book/example/lorem_book/all pages"
mv "/home/user/Documents/programs/split_book/example/lorem_book/all pages-1.pdf" \
 "/home/user/Documents/programs/split_book/example/lorem_book/all pages.pdf"
printf 'done!\n'
# INVALID CHAPTER "invalid 1"
printf 'invalid chapter "%s" because from=%i is greater than to=%i or to=%i is greater than book pages=%i\n' \
 "invalid 1" 2 1 1 3
# INVALID CHAPTER "invalid 2"
printf 'invalid chapter "%s" because from=%i is greater than to=%i or to=%i is greater than book pages=%i\n' \
 "invalid 2" 1 11 11 3
# INVALID CHAPTER "invalid 3"
printf 'invalid chapter "%s" because from=%i is greater than to=%i or to=%i is greater than book pages=%i\n' \
 "invalid 3" 7 11 11 3
# END OF PDFBOX SCRIPT
[INFO] running script "/tmp/split_book.pdfbox.sh" ...
generated pdfs will be saved in "/home/user/Documents/programs/split_book/example/lorem_book"
generating "first page.pdf" ... done!
generating "second page.pdf" ... done!
generating "third page.pdf" ... done!
generating "pages from 1 to 2.pdf" ... done!
generating "pages from 2 to 3.pdf" ... done!
generating "all pages.pdf" ... done!
invalid chapter "invalid 1" because from=2 is greater than to=1 or to=1 is greater than book pages=3
invalid chapter "invalid 2" because from=1 is greater than to=11 or to=11 is greater than book pages=3
invalid chapter "invalid 3" because from=7 is greater than to=11 or to=11 is greater than book pages=3
♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ 
Tyvm for using this program!
Muchas gracias por usar este programa!
Moitas grazas por usar este programa!
♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥ ♥
```

__NOTE:__ you can grant execution permission to the script _split_book.sh_ (```chmod u+x split_book.sh```) and add it to \$PATH (```export PATH=$PATH:<PATH_TO_SCRIPT>```).

## Exit Codes

|Code|Meaning|
|---|---|
|0|everything was coming up Milhouse|
|11|program was not launched with two arguments|
|13|book PDF file was not found|
|17|chapters XML file was not found|
|19|book PDF files was not a valid PDF file|
|23|generated config xml was not valid|

## Dependencies

This project uses a number of commands to work properly:

|Name|Description|Version|License|Installation|
|---|---|---|---|---|
|java|launch a Java application|17.0.13|GPLv2 with the Classpath Exception|```apt install openjdk-17-jdk```|
|pdfinfo|Portable Document Format (PDF) document information extractor|22.12.0|GPLv2 or GPLv3|```apt install poppler-utils```|
|grep|print lines matching a pattern|3.8|GPLv3+|```apt install grep```|
|dirname|strip non-directory suffix from file name|9.1|GPLv3+|```apt install coreutils```|
|basename|strip directory and suffix from filenames|9.1|GPLv3+|```apt install coreutils```|
|realpath|return the canonicalized absolute pathname|9.1|GPLv3+|```apt install coreutils```|
|tee|read from standard input and write to standard output and files|9.1|GPLv3+|```apt install coreutils```|
|printf|format and print data |9.1|GPLv3+|```apt install coreutils```|
|mv|move (rename) files|9.1|GPLv3+|```apt install coreutils```|
|mkdir|make directories|9.1|GPLv3+|```apt install coreutils```|
|cut|remove sections from each line of files|9.1|GPLv3+|```apt install coreutils```|

This project uses a number of JAR ("Java archive") files to work properly:

|Project|Website|Description|Version|License|Download|
|---|---|---|---|---|---|
|Apache PDFBox|https://pdfbox.apache.org/|Apache PDFBox is an open source tool for working with PDF documents in Java. It offers features such as text extraction, splitting, merging, form filling, signing, printing and more.|3.0.3|Apache License 2.0|https://dlcdn.apache.org/pdfbox/3.0.3/pdfbox-app-3.0.3.jar|
|Apache Xalan|https://xalan.apache.org/|The Apache Xalan Project develops and maintains libraries and programs that transform XML documents using XSLT standard stylesheets.|2.7.3|Apache License 2.0|https://dlcdn.apache.org/xalan/xalan-j/binaries/xalan-j_2_7_3-bin.tar.gz|
|Apache Xerces|https://xerces.apache.org/|Apache Xerces Project develops XML parsers and components in C++, Java, Perl and other languages. It supports XML 1.0, 1.1, XML Schema, XInclude, XML Catalogs and more standards and APIs|2.12.2|Apache License 2.0|https://dlcdn.apache.org//xerces/j/binaries/Xerces-J-bin.2.12.2.tar.gz|

## License

My knowledge on the subject of licensing is limited. So I asked it to ChatGPT 4o mini (sign up is not needed) the next question:

_"My project has components with the following licenses: Apache License 2.0, GPLv2 with the Classpath Exception, GPLv2,  GPLv3 and GPLv3+. What license should my project use?"_

I was given the next answer:

___BEGIN_OF_ANSWER___

Given your project's components licensed under Apache License 2.0, GPLv2 with Classpath Exception, GPLv2, GPLv3, and GPLv3+, here’s how you can approach selecting a suitable license:

1. **Apache License 2.0**: This is a permissive license that allows you to use, modify, and redistribute the code without imposing the same requirements on derivative works.

2. **GPLv2 with Classpath Exception**: This allows for linking with non-GPL code, making it somewhat flexible for use with other licenses.

3. **GPLv2**: This license requires that any derivative work also be licensed under GPLv2, which is less permissive.

4. **GPLv3 and GPLv3+**: These versions include more robust protections and requirements, and they are not compatible with GPLv2 unless explicitly stated (like in the case of the Classpath Exception).

### Recommended License for Your Project:

- **Use GPLv3 or GPLv3+**: This would be the most compatible choice. GPLv3 is compatible with GPLv2 (including the Classpath Exception), allowing you to include those components. Additionally, it can accommodate Apache-licensed components since they are generally compatible with GPLv3.

### Key Considerations:

- **Document Component Licenses**: Clearly indicate which parts of your project are licensed under which licenses to ensure transparency and compliance.
  
- **Compliance with Apache License**: If your project includes Apache-licensed components, make sure to adhere to the terms of that license as well.

### Summary:

Licensing your project under **GPLv3 or GPLv3+** is likely the best option, as it provides a comprehensive framework that accommodates all the licenses involved while ensuring compliance.

___END_OF_ANSWER___

Therefore, the license for this project is GPLv3 (see _gpl-3.0.txt_ file).

## Comments

1. I used XML instead of CSV, JSON or YAML, because to validate or transform a XML, it can be done declaratively using XSD and XSL.
2. I didn't use _pdfseparate_ and _pdfunite_ because sometimes, while _pdfunite_ was uniting the singles PDF pages generated by _pdfseparate_, it printed a lot times the next warning: _"Syntax Warning: PDFDoc::markDictionary: Found recursive dicts"_, and the new united PDF was bigger than the original PDF.  For example, _bash.pdf_ (https://www.gnu.org/software/bash/manual/bash.pdf) is __780K__ and has 196 pages, and after splitting it, from page 1 to page 98, and uniting it, the new PDF file called _half.pdf_ had 98 pages and it was __15M__!.
```
user@debian:~/Downloads$ ls
bash.pdf
user@debian:~/Downloads$ pdfinfo bash.pdf 
Creator:         TeX
Producer:        pdfTeX-1.40.22
CreationDate:    Mon Sep 26 17:15:05 2022 CEST
ModDate:         Mon Sep 26 17:15:05 2022 CEST
Custom Metadata: yes
Metadata Stream: no
Tagged:          no
UserProperties:  no
Suspects:        no
Form:            none
JavaScript:      no
Pages:           196
Encrypted:       no
Page size:       612 x 792 pts (letter)
Page rot:        0
File size:       795771 bytes
Optimized:       no
PDF version:     1.5
user@debian:~/Downloads$ pdfseparate -f 1 -l 98 bash.pdf %d.pdf
user@debian:~/Downloads$ ls
10.pdf  16.pdf  21.pdf  27.pdf  32.pdf  38.pdf  43.pdf  49.pdf  54.pdf  5.pdf   65.pdf  70.pdf  76.pdf  81.pdf  87.pdf  92.pdf  98.pdf
11.pdf  17.pdf  22.pdf  28.pdf  33.pdf  39.pdf  44.pdf  4.pdf   55.pdf  60.pdf  66.pdf  71.pdf  77.pdf  82.pdf  88.pdf  93.pdf  9.pdf
12.pdf  18.pdf  23.pdf  29.pdf  34.pdf  3.pdf   45.pdf  50.pdf  56.pdf  61.pdf  67.pdf  72.pdf  78.pdf  83.pdf  89.pdf  94.pdf  bash.pdf
13.pdf  19.pdf  24.pdf  2.pdf   35.pdf  40.pdf  46.pdf  51.pdf  57.pdf  62.pdf  68.pdf  73.pdf  79.pdf  84.pdf  8.pdf   95.pdf  half.pdf
14.pdf  1.pdf   25.pdf  30.pdf  36.pdf  41.pdf  47.pdf  52.pdf  58.pdf  63.pdf  69.pdf  74.pdf  7.pdf   85.pdf  90.pdf  96.pdf
15.pdf  20.pdf  26.pdf  31.pdf  37.pdf  42.pdf  48.pdf  53.pdf  59.pdf  64.pdf  6.pdf   75.pdf  80.pdf  86.pdf  91.pdf  97.pdf
user@debian:~/Downloads$ pdfunite [0-9]*.pdf half.pdf
Syntax Warning: PDFDoc::markDictionary: Found recursive dicts
Syntax Warning: PDFDoc::markDictionary: Found recursive dicts
...
Syntax Warning: PDFDoc::markDictionary: Found recursive dicts
Syntax Warning: PDFDoc::markDictionary: Found recursive dicts
user@debian:~/Downloads$ pdfinfo half.pdf 
Custom Metadata: no
Metadata Stream: no
Tagged:          no
UserProperties:  no
Suspects:        no
Form:            none
JavaScript:      no
Pages:           98
Encrypted:       no
Page size:       612 x 792 pts (letter)
Page rot:        0
File size:       15498196 bytes
Optimized:       no
PDF version:     1.5
```

## Mistakes ¯\\\_(ツ)\_/¯

1. I developed this project _offline_ without using git command.
2. I don't know exactly, how long this project lasted, because I didn't write down the dates and times I developed this project. I seem to remember that I started this project around September 2024 third week, and I finished it on Octber 2024 last week, and I programmed two or three hours a day, so this project lasted around 70 hours (5 weeks, two hours) or 105 hours (5 weeks, three hours).

## EOR (End Of Repository)

### I hope this program is useful to you, thanks you very much for visiting this repository!
### Espero que este programa te sea útil, muchas gracias por visitar este repositorio!
### Espero que este programa séache de utilidade, moitas grazas por visitar este repositorio!
