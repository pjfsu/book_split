#!/usr/bin/env bash

readonly EMPTY_ARG=""
readonly EMPTY_CSV="empty.csv"
readonly INVALID_PDF="invalid.pdf"
readonly PDF="valid.pdf"
readonly CSV="valid.csv"

echo PREPARING ...
[ -f book_split.sh ] && rm book_split.sh
[ -L book_split ] && rm book_split
[ -d valid ] && rm -rf valid
[ -d invalid ] && rm -rf invalid
chmod 400 $INVALID_PDF
chmod 400 $EMPTY_CSV
chmod 400 $PDF
chmod 400 $CSV
cp ../book_split.sh ./
chmod u+x book_split.sh
ln -s book_split.sh book_split
echo -e "DONE.\n"

echo TESTING book_split WORKS ...
book_split $PDF $CSV || exit 1
echo -e "DONE.\n"

echo TESTING book_split WORKS WITH EMPTY CSV ...
book_split $PDF $EMPTY_CSV|| exit 1
echo -e "DONE.\n"

echo TESTING PDF 404 ...
! book_split $EMPTY_ARG $CSV || exit 1
echo -e "DONE.\n"

echo TESTING CSV 404 ...
! book_split $PDF $EMPTY_ARG || exit 1
echo -e "DONE.\n"

echo TESTING INVALID PDF ...
! book_split $INVALID_PDF $CSV || exit 1
echo -e "DONE.\n"

echo TESTING PDF WITHOUT READ PERM ...
chmod -r $PDF
! book_split $PDF $CSV || exit 1
chmod +r $PDF
echo -e "DONE.\n"

echo TESTING CSV WITHOUT READ PERM ...
chmod -r $CSV
! book_split $PDF $CSV || exit 1
chmod +r $CSV
echo -e "DONE.\n"

echo CLEANING ...
[ -f book_split.sh ] && rm book_split.sh
[ -L book_split ] && rm book_split
[ -d valid ] && rm -rf valid
[ -d invalid ] && rm -rf invalid
echo -e "DONE.\n"

echo "DONE TESTS"
