FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y pdftk poppler-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENTRYPOINT ["bash", "/app/split_pdf.sh", "/app/example/lorem.csv"]
