from typing import Any, AsyncIterator
from fastapi.responses import StreamingResponse

async def iter_bytes(data: bytes) -> AsyncIterator[bytes]:
    """
    Wraps bytes in an async iterator so StreamingResponse can stream it.
    """
    yield data

def create_zip_response(content: bytes, filename: str) -> StreamingResponse:
    """
    Return a StreamingResponse for a ZIP file.
    """
    headers = {"Content-Disposition": f'attachment; filename="{filename}"'}
    return StreamingResponse(
        iter_bytes(content),
        media_type="application/zip",
        headers=headers
    )
