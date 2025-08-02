#!/usr/bin/env python3
"""
Extract PDF bookmarks/outlines, render per-depth CSVs,
and return them zipped as bytes.
"""

import csv
from io import StringIO
from collections import defaultdict
from typing import List, Dict, Union

from PyPDF2 import PdfReader
from PyPDF2.generic import Destination
from fastapi import UploadFile

from .utils import load_pdf_reader, package_zip, FALLBACK_PAGE
from .exceptions import NotFoundError

class Bookmark:
    """
    Represents a PDF outline entry with hierarchy level
    and start/end page indices.
    """
    def __init__(self, level: int, title: str, start_page: int, end_page: int = -1):
        self.level      = level
        self.title      = title.strip()
        self.start_page = start_page
        self.end_page   = end_page

async def build_bookmarks_zip(pdf_file: UploadFile) -> bytes:
    """
    1. Load PDF and read its outline.
    2. Flatten nested outline into Bookmark objects.
    3. Compute end pages.
    4. Group by level and render CSVs.
    5. ZIP and return CSV files as bytes.
    """
    reader  = await load_pdf_reader(pdf_file)
    outline = getattr(reader, "outline", None)
    if not outline:
        raise NotFoundError("No bookmarks found in the PDF")

    flat = _extract_flat_bookmarks(outline, reader)
    if not flat:
        raise NotFoundError("No bookmarks found in the PDF")

    _assign_end_pages(flat, total_pages=len(reader.pages))
    grouped = _group_by_level(flat)

    csv_files: Dict[str, bytes] = {}
    for level, bms in sorted(grouped.items()):
        csv_text = _render_csv(bms)
        csv_files[f"bookmarks_level_{level}.csv"] = csv_text.encode("utf-8")

    return package_zip(csv_files)

def _extract_flat_bookmarks(
    outline: List[Union[Destination, list]],
    reader: PdfReader,
    level: int = 0
) -> List[Bookmark]:
    """
    Recursively flatten the PDF outline into a list of Bookmark objects.
    """
    entries: List[Bookmark] = []
    for entry in outline:
        if isinstance(entry, list):
            entries.extend(_extract_flat_bookmarks(entry, reader, level + 1))
        elif isinstance(entry, Destination):
            try:
                page = reader.get_destination_page_number(entry) + 1
            except Exception:
                page = FALLBACK_PAGE
            entries.append(Bookmark(level, entry.title, page))
    return entries

def _assign_end_pages(bookmarks: List[Bookmark], total_pages: int) -> None:
    """
    For each bookmark, set end_page to one less than the next sibling's start
    or to the document's last page.
    """
    for idx, bm in enumerate(bookmarks):
        bm.end_page = total_pages
        for next_bm in bookmarks[idx + 1:]:
            if next_bm.level <= bm.level:
                bm.end_page = next_bm.start_page - 1
                break

def _group_by_level(bookmarks: List[Bookmark]) -> Dict[int, List[Bookmark]]:
    """
    Group bookmarks into a dict keyed by depth level.
    """
    by_level: Dict[int, List[Bookmark]] = defaultdict(list)
    for bm in bookmarks:
        by_level[bm.level].append(bm)
    return by_level

def _render_csv(bookmarks: List[Bookmark]) -> str:
    """
    Serialize a list of Bookmark objects to CSV:
    columns: split, name, from, to
    """
    buf = StringIO()
    writer = csv.writer(buf, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow(["split", "name", "from", "to"])
    for bm in bookmarks:
        writer.writerow(["n", bm.title, bm.start_page, bm.end_page])
    return buf.getvalue()

