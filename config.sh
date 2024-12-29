### Configuration for split_book.sh
readonly ARGS_LEN=2

# Directories
readonly THIS_SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly XML_DIR="${THIS_SCRIPT_DIR}/xml"

# XML Files
readonly BOOK_INFO_XSD="${XML_DIR}/book_info.xsd"
readonly BOOK_INFO_XSL="${XML_DIR}/book_info.xsl"

# Temporary Files
readonly BOOK_INFO_XML="$(mktemp)"
readonly CHAPS_CSV="$(mktemp)"

# Error Codes
readonly ARGS_LEN_NOT_VALID_ERR_CODE=11
readonly BOOK_PDF_NOT_VALID_ERR_CODE=13
readonly BOOK_INFO_XML_NOT_VALID_ERR_CODE=17
readonly BOOK_PDF_NOT_FOUND_ERR_CODE=19
readonly CHAPS_XML_NOT_FOUND_ERR_CODE=23

# Error Messages
readonly ARGS_LEN_NOT_VALID_ERR_MSG="usage: \"./split_book.sh book.pdf chapter.xml\""
readonly BOOK_PDF_NOT_VALID_ERR_MSG="not valid book.pdf" 
readonly BOOK_INFO_XML_NOT_VALID_ERR_MSG="not valid book_info.xml"
readonly BOOK_PDF_NOT_FOUND_ERR_MSG="not found book.pdf" 
readonly CHAPS_XML_NOT_FOUND_ERR_MSG="not found chapters.xml"
