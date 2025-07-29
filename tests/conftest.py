# tests/conftest.py

import os
import io
import zipfile

import pytest
import requests
import PyPDF2

# Base URL for the running service under test
API_URL = os.getenv("API_URL", "http://host.containers.internal:8080")


@pytest.fixture(scope="session")
def client():
    """
    Simple HTTP client that prefixes every request path with the API_URL.
    """
    class Client:
        def post(self, path, **kwargs):
            return requests.post(f"{API_URL}{path}", **kwargs)

    return Client()


@pytest.fixture
def pdf_with_bookmarks() -> io.BytesIO:
    """
    In-memory PDF with two outline levels:
      * Level 0: 'Chapter 1', 'Chapter 2'
      * Level 1: 'Section 1.1', 'Section 1.2' under 'Chapter 1'
    """
    writer = PyPDF2.PdfWriter()
    # Create three blank pages
    for _ in range(3):
        writer.add_blank_page(width=72, height=72)

    # Top-level bookmark
    chap1 = writer.add_outline_item("Chapter 1", page_number=0)
    # Nested bookmarks
    writer.add_outline_item("Section 1.1", page_number=1, parent=chap1)
    writer.add_outline_item("Section 1.2", page_number=2, parent=chap1)
    # Second top-level bookmark
    writer.add_outline_item("Chapter 2", page_number=2)

    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


@pytest.fixture
def pdf_without_bookmarks() -> io.BytesIO:
    """
    In-memory PDF with no bookmarks at all.
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
    In-memory, password-protected PDF.
    """
    writer = PyPDF2.PdfWriter()
    writer.add_blank_page(width=72, height=72)
    writer.encrypt("secret")

    buf = io.BytesIO()
    writer.write(buf)
    buf.seek(0)
    return buf


def extract_zip_csvs(zip_bytes: bytes) -> dict:
    """
    Given raw ZIP bytes, return a dict of {filename: decoded text}.
    """
    buf = io.BytesIO(zip_bytes)
    with zipfile.ZipFile(buf) as zf:
        return {
            name: zf.read(name).decode("utf-8")
            for name in zf.namelist()
        }

