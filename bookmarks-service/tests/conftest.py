# tests/conftest.py

import os
import io
import zipfile
from typing import Dict
import pytest
import requests
import PyPDF2

# Base URL for the running service under test
API_URL = os.getenv("API_URL", "http://split-pdf-bookmarks:8080")


class APIClient:
    """
    Wraps a requests.Session and auto-prefixes every path
    with the API_URL.
    """
    def __init__(self):
        self._sess = requests.Session()

    def post(self, path: str, **kwargs):
        return self._sess.post(f"{API_URL}{path}", **kwargs)


@pytest.fixture(scope="session")
def client() -> APIClient:
    """
    Returns an APIClient capable of posting to our service.
    """
    return APIClient()


@pytest.fixture
def pdf_with_bookmarks() -> io.BytesIO:
    """
    3-page PDF with:
      - Level-0 bookmarks "Chapter 1" & "Chapter 2"
      - Level-1 bookmarks "Section 1.1" & "Section 1.2" under Chapter 1
    """
    writer = PyPDF2.PdfWriter()
    for _ in range(3):
        writer.add_blank_page(width=72, height=72)

    chap1 = writer.add_outline_item("Chapter 1", page_number=0)
    writer.add_outline_item("Section 1.1", page_number=1, parent=chap1)
    writer.add_outline_item("Section 1.2", page_number=2, parent=chap1)
    writer.add_outline_item("Chapter 2", page_number=2)

    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


@pytest.fixture
def pdf_without_bookmarks() -> io.BytesIO:
    """
    1-page blank PDF with no bookmarks.
    """
    writer = PyPDF2.PdfWriter()
    writer.add_blank_page(width=72, height=72)
    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


@pytest.fixture
def encrypted_pdf() -> io.BytesIO:
    """
    1-page PDF encrypted with password "secret".
    """
    writer = PyPDF2.PdfWriter()
    writer.add_blank_page(width=72, height=72)
    writer.encrypt("secret")
    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


@pytest.fixture
def pdf_4pages() -> io.BytesIO:
    """
    4-page blank PDF for split-by-CSV tests.
    """
    writer = PyPDF2.PdfWriter()
    for _ in range(4):
        writer.add_blank_page(width=72, height=72)
    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


def extract_zip_contents(zip_bytes: bytes) -> Dict[str, bytes]:
    """
    Unpack a ZIP from bytes --> {filename: raw bytes}.
    """
    buf = io.BytesIO(zip_bytes)
    with zipfile.ZipFile(buf) as zf:
        return {n: zf.read(n) for n in zf.namelist()}


def extract_zip_csvs(zip_bytes: bytes) -> Dict[str, str]:
    """
    Unpack a ZIP from bytes --> {filename: UTF-8 text}.
    """
    raw = extract_zip_contents(zip_bytes)
    return {n: data.decode("utf-8") for n, data in raw.items()}

