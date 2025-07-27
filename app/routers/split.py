from fastapi import APIRouter, File, UploadFile, HTTPException
from fastapi.responses import StreamingResponse

from .utils import create_zip_response
from services.split import split_pdf_by_csv as split_pdf_by_csv_service

router = APIRouter(
    prefix="/api",
    tags=["split"],
    responses={400: {"description": "Bad Request"}}
)

@router.post(
    "/split",
    summary="Split a PDF into chapters based on a CSV of bookmarks page ranges",
    response_class=StreamingResponse
)
async def split_pdf_by_csv(
    pdf: UploadFile = File(..., description="Original PDF to split"),
    csvfile: UploadFile = File(..., description="CSV with columns: split,name,from,to")
) -> StreamingResponse:
    """
    Reads the CSV file, each row defining a [split,name,from,to] range,
    splits the PDF accordingly (if split=='y'), 
    zips the result, 
    and returns the ZIP archive.
    """
    try:
        zip_bytes = await split_pdf_by_csv_service(pdf, csvfile)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    return create_zip_response(zip_bytes, "chapters.zip")
