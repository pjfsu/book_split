FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y pdftk poppler-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app.sh /app/app.sh

RUN chmod +x /app/app.sh

ENTRYPOINT ["bash", "/app/app.sh"]
