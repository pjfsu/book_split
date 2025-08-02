# tests/test_bookmarks_zip.py

import io
import pytest

from .conftest import client, pdf_with_bookmarks, pdf_without_bookmarks, encrypted_pdf, extract_zip_csvs


def test_successful_export_multilevel_bookmarks(client, pdf_with_bookmarks):
    """
    POST /api/bookmarks/zip with nested outlines -->
    200 OK + ZIP containing level_0 + level_1 CSVs.
    """
    resp = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("with_bookmarks.pdf", pdf_with_bookmarks, "application/pdf")},
    )
    assert resp.status_code == 200
    assert "application/zip" in resp.headers["content-type"]

    csvs = extract_zip_csvs(resp.content)
    # Level 0
    assert "bookmarks_level_0.csv" in csvs
    assert "Chapter 1" in csvs["bookmarks_level_0.csv"]
    assert "Chapter 2" in csvs["bookmarks_level_0.csv"]
    # Level 1
    assert "bookmarks_level_1.csv" in csvs
    assert "Section 1.1" in csvs["bookmarks_level_1.csv"]
    assert "Section 1.2" in csvs["bookmarks_level_1.csv"]


def test_no_bookmarks_returns_404(client, pdf_without_bookmarks):
    """
    POST /api/bookmarks/zip with no bookmarks -->
    404 Not Found + detail "No bookmarks found in the PDF".
    """
    resp = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("no_bookmarks.pdf", pdf_without_bookmarks, "application/pdf")},
    )
    assert resp.status_code == 404
    assert resp.json()["detail"] == "No bookmarks found in the PDF"


@pytest.mark.parametrize(
    "fname, data, mime",
    [
        ("not_a_pdf.txt", b"hello world", "text/plain"),
        ("trunc.pdf", b"%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\nendobj\n", "application/pdf"),
    ],
)
def test_invalid_or_truncated_pdf_raises_400(client, fname, data, mime):
    """
    Non‐PDF or truncated PDF --> 400 Bad Request + detail contains "invalid pdf file".
    """
    buf = io.BytesIO(data)
    resp = client.post(
        "/api/bookmarks/zip",
        files={"pdf": (fname, buf, mime)},
    )
    assert resp.status_code == 400
    assert "invalid pdf file" in resp.json()["detail"].lower()


def test_encrypted_pdf_returns_password_protected_error(client, encrypted_pdf):
    """
    Password‐protected PDF --> 400 or 403 + detail "pdf is password-protected".
    """
    resp = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("encrypted.pdf", encrypted_pdf, "application/pdf")},
    )
    assert resp.status_code in (400, 403)
    assert "pdf is password-protected" in resp.json()["detail"].lower()

