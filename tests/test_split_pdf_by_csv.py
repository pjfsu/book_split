# tests/test_split_pdf_by_csv.py

import io
import pytest
import PyPDF2

from .conftest import client, pdf_4pages, extract_zip_contents


class TestSplitEndpoint:
    endpoint = "/api/split"

    def test_successful_split(self, client, pdf_4pages):
        """
        Valid PDF + CSV with some 'y' flags --> ZIP of only those fragments.
        """
        csv_lines = [
            "split,name,from,to",
            "y,Part A,1,2",
            "n,Ignore Me,2,3",
            "y,Part B,3,4",
        ]
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("ranges.csv", io.BytesIO("\n".join(csv_lines).encode()), "text/csv"),
        }

        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert "application/zip" in resp.headers["content-type"]

        frags = extract_zip_contents(resp.content)
        assert len(frags) == 2
        names = set(frags)
        assert any("Part A" in fn for fn in names)
        assert any("Part B" in fn for fn in names)

        # Each PDF fragment has exactly 2 pages
        for data in frags.values():
            reader = PyPDF2.PdfReader(io.BytesIO(data))
            assert len(reader.pages) == 2

    @pytest.mark.parametrize(
        "csv_body, expected_substr",
        [
            ("split,name,from,to\ny,Title,one,2", "non-integer"),
            ("split,name,from,to\ny,T1,0,1", "below 1"),
            ("split,name,from,to\ny,T2,3,2", "before start"),
            ("split,name,from,to\ny,T3,1,5", "exceeds total"),
        ]
    )
    def test_invalid_csv_or_ranges(self, client, pdf_4pages, csv_body, expected_substr):
        """
        Bad CSV or OOB ranges --> 400 + detail explains the error.
        """
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("ranges.csv", io.BytesIO(csv_body.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 400
        assert expected_substr in resp.json()["detail"].lower()

    def test_all_n_flags_yields_empty_zip(self, client, pdf_4pages):
        """
        CSV all 'n' --> empty ZIP (no entries) but still 200 OK.
        """
        csv_content = "split,name,from,to\nn,First,1,2\nn,Second,3,4\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("ranges.csv", io.BytesIO(csv_content.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert extract_zip_contents(resp.content) == {}

    @pytest.mark.parametrize(
        "fname, data, mime, expected_substr",
        [
            ("not_a_pdf.txt", b"hello world", "text/plain", "invalid pdf"),
            ("trunc.pdf", b"%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\nendobj\n", "application/pdf", "invalid pdf"),
        ]
    )
    def test_bad_pdf_input_raises_400(self, client, fname, data, mime, expected_substr):
        """
        Non‐PDF or truncated PDF --> 400 + detail contains 'invalid pdf'.
        """
        files = {
            "pdf": (fname, io.BytesIO(data), mime),
            "csvfile": ("ranges.csv", io.BytesIO(b"split,name,from,to\ny,A,1,1\n"), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 400
        assert expected_substr in resp.json()["detail"].lower()

    def test_encrypted_pdf_rejected(self, client, encrypted_pdf):
        """
        Encrypted PDF --> 400 + detail 'password-protected'.
        """
        files = {
            "pdf": ("encrypted.pdf", encrypted_pdf, "application/pdf"),
            "csvfile": ("ranges.csv", io.BytesIO(b"split,name,from,to\ny,A,1,1\n"), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 400
        assert "password-protected" in resp.json()["detail"].lower()

    def test_empty_csv_returns_empty_zip(self, client, pdf_4pages):
        """
        Zero‐byte CSV --> 200 OK + empty ZIP.
        """
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("empty.csv", io.BytesIO(b""), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert extract_zip_contents(resp.content) == {}

    def test_header_only_csv_returns_empty_zip(self, client, pdf_4pages):
        """
        CSV with only header --> 200 OK + empty ZIP.
        """
        buf = io.BytesIO(b"split,name,from,to\n")
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("header_only.csv", buf, "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert extract_zip_contents(resp.content) == {}

    def test_csv_with_bom_on_header(self, client, pdf_4pages):
        """
        Header line prefixed with UTF-8 BOM --> empty ZIP (no header match).
        """
        bom = b"\xef\xbb\xbf"
        lines = bom + b"split,name,from,to\ny,Segment,1,2\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("bom.csv", io.BytesIO(lines), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert extract_zip_contents(resp.content) == {}

    def test_csv_with_extra_columns_ignored(self, client, pdf_4pages):
        """
        Extra/reordered columns beyond split,name,from,to are ignored.
        """
        csv = "\n".join([
            "foo,from,split,name,to,bar",
            "x,1,y,Title,1,2,z",
        ])
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("extra.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        frags = extract_zip_contents(resp.content)
        assert len(frags) == 1
        assert any("Title" in fn for fn in frags)

    def test_missing_required_header_raises_400(self, client, pdf_4pages):
        """
        Missing one of split/name/from/to headers --> 400 with non-integer error.
        """
        # 'from' header replaced by 'foo'
        bad_header = b"split,name,foo,to\ny,Name,1,2\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("bad_header.csv", io.BytesIO(bad_header), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 400
        # currently manifests as a non-integer page range error
        assert "non-integer" in resp.json()["detail"].lower()

    @pytest.mark.parametrize("flag", ["", " ", "x", "0"])
    def test_blank_or_invalid_flag_cell_treated_as_n(self, client, pdf_4pages, flag):
        """
        Blank or non-'y' flag --> row skipped.
        """
        csv = f"split,name,from,to\n{flag},SkipMe,1,1\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("flags.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        assert extract_zip_contents(resp.content) == {}

    @pytest.mark.parametrize("flag", ["Y", "y"])
    def test_case_insensitive_flag(self, client, pdf_4pages, flag):
        """
        Uppercase 'Y' flag treated like lowercase.
        """
        csv = f"split,name,from,to\n{flag},CaseTest,2,3\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("case.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        frags = extract_zip_contents(resp.content)
        assert resp.status_code == 200
        assert len(frags) == 1
        reader = PyPDF2.PdfReader(io.BytesIO(next(iter(frags.values()))))
        assert len(reader.pages) == 2

    def test_blank_name_triggers_fallback(self, client, pdf_4pages):
        """
        Empty name --> fallback to part_{start}_{end}.pdf.
        """
        csv = "split,name,from,to\ny,,2,3\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("nofname.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        frags = extract_zip_contents(resp.content)
        assert resp.status_code == 200
        assert list(frags.keys()) == ["part_2_3.pdf"]

    def test_illegal_name_characters_sanitized(self, client, pdf_4pages):
        """
        Names with illegal characters get "_" replacements,
        leading/trailing "_" stripped.
        """
        name = "Bad:/Name*?"
        csv = f"split,name,from,to\ny,{name},1,2\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("badname.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200

        frags = extract_zip_contents(resp.content)
        assert list(frags.keys()) == ["Bad__Name.pdf"]

    @pytest.mark.parametrize(
        "csv_body, expected_substr",
        [
            ("split,name,from,to\ny,A,,2", "non-integer"),
            ("split,name,from,to\ny,A,1,", "non-integer"),
        ]
    )
    def test_missing_from_to_fields_raises_400(self, client, pdf_4pages, csv_body, expected_substr):
        """
        Blank/missing 'from' or 'to' --> 400 non-integer error.
        """
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("missing_range.csv", io.BytesIO(csv_body.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 400
        assert expected_substr in resp.json()["detail"].lower()

    def test_overlapping_ranges_processed(self, client, pdf_4pages):
        """
        Overlapping ranges --> both fragments produced.
        """
        csv = "\n".join([
            "split,name,from,to",
            "y,First,1,3",
            "y,Second,2,4",
        ])
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("overlap.csv", io.BytesIO(csv.encode()), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        frags = extract_zip_contents(resp.content)
        assert resp.status_code == 200
        assert len(frags) == 2
        for data in frags.values():
            reader = PyPDF2.PdfReader(io.BytesIO(data))
            assert len(reader.pages) == 3

    def test_non_utf8_csv_bytes_processed(self, client, pdf_4pages):
        """
        Latin-1 encoded CSV bytes should not crash parser.
        """
        raw = b"split,name,from,to\n" + b"y,Part \xc1,1,2\n"
        files = {
            "pdf": ("doc.pdf", pdf_4pages, "application/pdf"),
            "csvfile": ("latin1.csv", io.BytesIO(raw), "text/csv"),
        }
        resp = client.post(self.endpoint, files=files)
        assert resp.status_code == 200
        frags = extract_zip_contents(resp.content)
        assert len(frags) == 1
        reader = PyPDF2.PdfReader(io.BytesIO(next(iter(frags.values()))))
        assert len(reader.pages) == 2

