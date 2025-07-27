#!/usr/bin/env python3
"""
Split a PDF into multiple parts based on CSV instructions,
then ZIP and return the resulting fragments.
"""

import csv
from io import StringIO, BytesIO
from dataclasses import dataclass
from typing import List, Dict

from fastapi import UploadFile
from PyPDF2 import PdfReader, PdfWriter

from .utils import (
    load_pdf_reader,
    read_bytes,
    package_zip,
    sanitize_filename,
    CSV_ENCODING,
    CSV_ERRORS
)
from .exceptions import ValidationError

@dataclass
class SplitInstruction:
    """
    One row from CSV: whether to split, title, and page range.
    """
    should_split: bool
    title:        str
    start_page:   int
    end_page:     int

async def split_pdf_by_csv(pdf_file: UploadFile, csv_file: UploadFile) -> bytes:
    """
    1. Load PDF reader.
    2. Parse CSV into SplitInstruction list.
    3. Validate each instruction.
    4. Extract requested fragments.
    5. ZIP fragments and return bytes.
    """
    reader       = await load_pdf_reader(pdf_file)
    instructions = await _parse_csv(csv_file)

    _validate(instructions, total_pages=len(reader.pages))
    fragments = _extract_fragments(reader, instructions)

    return package_zip(fragments)

async def _parse_csv(csv_file: UploadFile) -> List[SplitInstruction]:
    """
    Decode and parse CSV into SplitInstruction list.
    Expected headers: split (y/n), name, from, to.
    """
    raw  = await read_bytes(csv_file)
    text = raw.decode(CSV_ENCODING, errors=CSV_ERRORS)
    try:
        rows = csv.DictReader(StringIO(text))
    except Exception as e:
        raise ValidationError(f"Invalid CSV format: {e}")

    instructions: List[SplitInstruction] = []
    for row in rows:
        flag = row.get("split", "").strip().lower() == "y"
        name = row.get("name", "").strip()
        frm  = row.get("from", "").strip()
        to   = row.get("to", "").strip()

        try:
            start = int(frm)
            end   = int(to)
        except ValueError:
            raise ValidationError(f"Non-integer page range in row: {row}")

        instructions.append(SplitInstruction(flag, name, start, end))

    return instructions

def _validate(instructions: List[SplitInstruction], total_pages: int) -> None:
    """
    Ensure each flagged instruction has a valid page range
    within [1, total_pages] and start ≤ end.
    """
    for inst in instructions:
        if not inst.should_split:
            continue
        if inst.start_page < 1:
            raise ValidationError(f"Start page {inst.start_page} is below 1")
        if inst.end_page < inst.start_page:
            raise ValidationError(
                f"End page {inst.end_page} is before start page {inst.start_page}"
            )
        if inst.end_page > total_pages:
            raise ValidationError(
                f"End page {inst.end_page} exceeds total page count ({total_pages})"
            )

def _extract_fragments(
    reader: PdfReader,
    instructions: List[SplitInstruction]
) -> Dict[str, bytes]:
    """
    For each instruction flagged to split, extract the page range,
    write a new PDF in memory, and collect filename→bytes.
    """
    fragments: Dict[str, bytes] = {}

    for inst in instructions:
        if not inst.should_split:
            continue

        writer = PdfWriter()
        for idx in range(inst.start_page - 1, inst.end_page):
            writer.add_page(reader.pages[idx])

        fname = sanitize_filename(inst.title, inst.start_page, inst.end_page) + ".pdf"
        buffer = BytesIO()
        writer.write(buffer)
        fragments[fname] = buffer.getvalue()

    return fragments
