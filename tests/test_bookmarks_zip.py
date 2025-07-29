# tests/test_bookmarks_zip.py

import io
import pytest

from .conftest import extract_zip_csvs

# Fixtures and helpers are imported automatically from conftest.py


def test_successful_export_multilevel_bookmarks(client, pdf_with_bookmarks):
    """
    When uploading a PDF with nested outlines,
    expect HTTP 200 OK and a ZIP containing level-0 and level-1 CSVs
    with the correct chapter/section titles.
    """
    response = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("with_bookmarks.pdf", pdf_with_bookmarks, "application/pdf")},
    )
    assert response.status_code == 200, "Expected 200 OK for valid PDF"
    assert "application/zip" in response.headers["content-type"]

    csvs = extract_zip_csvs(response.content)

    # Level-0 entries must list Chapter 1 & Chapter 2
    assert "bookmarks_level_0.csv" in csvs, "Missing level-0 CSV"
    assert "Chapter 1" in csvs["bookmarks_level_0.csv"]
    assert "Chapter 2" in csvs["bookmarks_level_0.csv"]

    # Level-1 entries must list Section 1.1 & Section 1.2
    assert "bookmarks_level_1.csv" in csvs, "Missing level-1 CSV"
    assert "Section 1.1" in csvs["bookmarks_level_1.csv"]
    assert "Section 1.2" in csvs["bookmarks_level_1.csv"]


def test_no_bookmarks_returns_404(client, pdf_without_bookmarks):
    """
    Uploading a PDF with zero bookmarks should return 404 Not Found
    and detail 'No bookmarks found in the PDF'.
    """
    response = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("no_bookmarks.pdf", pdf_without_bookmarks, "application/pdf")},
    )
    assert response.status_code == 404, "Expected 404 for PDFs without bookmarks"
    assert response.json()["detail"] == "No bookmarks found in the PDF"


@pytest.mark.parametrize(
    "filename, content, mime, expected_detail",
    [
        ("not_a_pdf.txt", b"hello world", "text/plain", "invalid pdf file"),
        ("truncated.pdf", b"%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\nendobj\n", "application/pdf", "invalid pdf file"),
    ],
)
def test_invalid_or_truncated_pdf_raises_400(client, filename, content, mime, expected_detail):
    """
    Sending non-PDF or truncated PDF data should yield 400 Bad Request
    with a detail containing 'invalid pdf file'.
    """
    buf = io.BytesIO(content)
    response = client.post(
        "/api/bookmarks/zip",
        files={"pdf": (filename, buf, mime)},
    )
    assert response.status_code == 400, f"Expected 400 for {filename}"
    assert expected_detail in response.json()["detail"].lower()


def test_encrypted_pdf_returns_password_protected_error(client, encrypted_pdf):
    """
    A password-protected PDF should be rejected (400 or 403)
    with a detail mentioning 'pdf is password-protected'.
    """
    response = client.post(
        "/api/bookmarks/zip",
        files={"pdf": ("encrypted.pdf", encrypted_pdf, "application/pdf")},
    )
    assert response.status_code in (400, 403), "Encrypted PDF must be rejected"
    assert "pdf is password-protected" in response.json()["detail"].lower()

