#!/usr/bin/env python3
"""
Common service utilities: PDF loading, byte reading, ZIP packaging,
filename sanitization, and shared constants.
"""

import zipfile
from io import BytesIO
from typing import Dict

from fastapi import UploadFile
from PyPDF2 import PdfReader

from .exceptions import ValidationError

# CSV decoding parameters
CSV_ENCODING = "utf-8"
CSV_ERRORS   = "ignore"

# Filename sanitization
FILENAME_WHITELIST         = set("abcdefghijklmnopqrstuvwxyz"
                                 "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                 "0123456789"
                                 " _-.")
FALLBACK_FILENAME_PATTERN  = "part_{start}_{end}"
FALLBACK_PAGE              = 1

async def read_bytes(file: UploadFile) -> bytes:
    """
    Read all bytes from an UploadFile.
    """
    return await file.read()

async def load_pdf_reader(pdf_file: UploadFile) -> PdfReader:
    """
    Load PDF bytes into a PdfReader. Raises ValidationError if invalid.
    """
    data = await read_bytes(pdf_file)
    try:
        return PdfReader(BytesIO(data))
    except Exception as e:
        raise ValidationError(f"Invalid PDF file: {e}")

def package_zip(files: Dict[str, bytes]) -> bytes:
    """
    Package a mapping of filename→bytes into a ZIP archive.
    Returns the raw ZIP bytes.
    """
    buffer = BytesIO()
    with zipfile.ZipFile(buffer, mode="w", compression=zipfile.ZIP_DEFLATED) as archive:
        for filename, content in files.items():
            archive.writestr(filename, content)
    buffer.seek(0)
    return buffer.read()

def sanitize_filename(title: str, start: int, end: int) -> str:
    """
    Produce a filesystem-safe basename from a title.
    Falls back to a numeric pattern if the cleaned title is empty.
    """
    cleaned = "".join(
        ch if ch in FILENAME_WHITELIST else "_"
        for ch in (title or "")
    ).strip("_")
    if not cleaned:
        cleaned = FALLBACK_FILENAME_PATTERN.format(start=start, end=end)
    return cleaned
