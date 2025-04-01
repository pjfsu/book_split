FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y pdftk poppler-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY split_pdf.sh /app/split_pdf.sh

RUN chmod +x /app/split_pdf.sh

ENTRYPOINT ["bash", "/app/split_pdf.sh", "/tmp/in.pdf", "/tmp/in.csv"]
