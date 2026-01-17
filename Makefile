# Makefile for PostgreSQL Backup Worker

# Variables
POSTGRES_VERSION ?= 18.1
IMAGE_NAME ?= pg-dump-to-s3

.PHONY: help build clean test test-db-up test-db-down

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image (context: project root)
	docker build \
		--build-arg POSTGRES_VERSION=$(POSTGRES_VERSION) \
		-t $(IMAGE_NAME):$(POSTGRES_VERSION) \
		-t $(IMAGE_NAME):latest \
		-f postgres-backup/Dockerfile \
		.

clean: ## Remove Docker images
	docker rmi $(IMAGE_NAME):$(POSTGRES_VERSION) 2>/dev/null || true
	docker rmi $(IMAGE_NAME):test 2>/dev/null || true
	docker rmi $(IMAGE_NAME):latest 2>/dev/null || true

test-db-up: ## Start the test PostgreSQL database
	docker compose -f postgres-backup/compose.test.yml up -d

test-db-down: ## Stop and remove the test PostgreSQL database
	docker compose -f postgres-backup/compose.test.yml down -v

test: ## Run the backup test (requires test DB running)
	docker run --rm \
		--network host \
		-e DB_HOST=localhost \
		-e DB_PORT=5432 \
		-e DB_USER=postgres \
		-e DB_PASSWORD=testpass \
		-e DB_NAME=testdb \
		-e BACKUP_NAME=test_backup \
		-e SKIP_S3_UPLOAD=true \
		$(IMAGE_NAME):$(POSTGRES_VERSION)
