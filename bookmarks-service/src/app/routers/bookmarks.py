from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import StreamingResponse

from .utils import create_zip_response
from services.bookmarks import build_bookmarks_zip as build_bookmarks_zip_service
from services.exceptions import NotFoundError

router = APIRouter(
    prefix="/api",
    tags=["bookmarks"],
    responses={404: {"description": "Not Found"}, 400: {"description": "Bad Request"}}
)

@router.post(
    "/bookmarks/zip",
    summary="Export PDF bookmarks as per-depth CSVs inside a ZIP",
    response_class=StreamingResponse
)
async def export_bookmarks_zip(
    pdf: UploadFile = File(..., description="A PDF file containing bookmarks")
) -> StreamingResponse:
    """
    Parse the uploaded PDF, extract its outline/bookmarks grouped by depth,
    generate one CSV per depth level, and return them all in a ZIP archive.
    """
    try:
        zip_bytes = await build_bookmarks_zip_service(pdf)
    except NotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return create_zip_response(zip_bytes, "bookmarks_by_depth.zip")
