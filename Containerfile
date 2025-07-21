FROM docker.io/debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends pdftk poppler-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app.sh .
RUN mkdir -p in out

ENV IN_DIR=/app/in \
    OUT_DIR=/app/out \
    BOOK=/app/in/book.pdf \
    CHAPTERS=/app/in/chapters.csv

ENTRYPOINT ["bash", "app.sh"]
