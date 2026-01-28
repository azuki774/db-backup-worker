FROM alpine:3.23

ARG MARIADB_VERSION=11.4

RUN apk add --no-cache \
    bash \
    curl \
    mariadb-client \
    aws-cli

WORKDIR /app

COPY ./mariadb-backup/entrypoint.sh ./mariadb-backup/backup.sh ./mariadb-backup/verify.sh /app/
COPY ./scripts/common.sh /app/scripts/
COPY ./scripts/s3-upload.sh /app/scripts/

RUN chmod +x /app/*.sh /app/scripts/*.sh

ENV DB_HOST=localhost \
    DB_PORT=3306 \
    DB_USER=root \
    SKIP_S3_UPLOAD=false

ENTRYPOINT ["/app/entrypoint.sh"]
