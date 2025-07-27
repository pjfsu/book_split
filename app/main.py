# app/main.py
from fastapi import FastAPI
from routers.split import router as split_router
from routers.bookmarks import router as bookmarks_router

app = FastAPI(
    title="PDF Splitter by CSV Bookmarks Ranges",
    version="1.0.0",
    description="Split a PDF using CSV‐defined bookmarks page ranges."
)

# Mount routers
app.include_router(split_router)
app.include_router(bookmarks_router)
