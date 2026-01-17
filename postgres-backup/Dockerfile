FROM alpine:3.23

ARG POSTGRES_VERSION=18.1

RUN apk add --no-cache \
    bash \
    curl \
    postgresql$(echo ${POSTGRES_VERSION} | cut -d. -f1)-client \
    aws-cli

WORKDIR /app

COPY ./postgres-backup/entrypoint.sh ./postgres-backup/backup.sh ./postgres-backup/verify.sh /app/
COPY ./scripts/common.sh /app/scripts/
COPY ./scripts/s3-upload.sh /app/scripts/

RUN chmod +x /app/*.sh /app/scripts/*.sh

ENV DB_HOST=localhost \
    DB_PORT=5432 \
    DB_USER=postgres \
    SKIP_S3_UPLOAD=false

ENTRYPOINT ["/app/entrypoint.sh"]
