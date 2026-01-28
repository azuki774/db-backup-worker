# Makefile for DB Backup Worker

# Variables
POSTGRES_VERSION ?= 18.1
MARIADB_VERSION ?= 11.4
PG_IMAGE_NAME ?= pg-dump-to-s3
MARIA_IMAGE_NAME ?= mariadb-dump-to-s3

.PHONY: help build clean test test-db-up test-db-down
.PHONY: build-mariadb clean-mariadb test-mariadb test-mariadb-db-up test-mariadb-db-down

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# PostgreSQL targets
build: ## Build the PostgreSQL Docker image
	docker build \
		--build-arg POSTGRES_VERSION=$(POSTGRES_VERSION) \
		-t $(PG_IMAGE_NAME):$(POSTGRES_VERSION) \
		-t $(PG_IMAGE_NAME):latest \
		-f postgres-backup/Dockerfile \
		.

clean: ## Remove PostgreSQL Docker images
	docker rmi $(PG_IMAGE_NAME):$(POSTGRES_VERSION) 2>/dev/null || true
	docker rmi $(PG_IMAGE_NAME):test 2>/dev/null || true
	docker rmi $(PG_IMAGE_NAME):latest 2>/dev/null || true

test-db-up: ## Start the test PostgreSQL database
	docker compose -f postgres-backup/compose.test.yml up -d

test-db-down: ## Stop and remove the test PostgreSQL database
	docker compose -f postgres-backup/compose.test.yml down -v

test: ## Run the PostgreSQL backup test (requires test DB running)
	docker run --rm \
		--network host \
		-e DB_HOST=localhost \
		-e DB_PORT=5432 \
		-e DB_USER=postgres \
		-e DB_PASSWORD=testpass \
		-e DB_NAME=testdb \
		-e BACKUP_NAME=test_backup \
		-e SKIP_S3_UPLOAD=true \
		$(PG_IMAGE_NAME):$(POSTGRES_VERSION)

# MariaDB targets
build-mariadb: ## Build the MariaDB Docker image
	docker build \
		--build-arg MARIADB_VERSION=$(MARIADB_VERSION) \
		-t $(MARIA_IMAGE_NAME):$(MARIADB_VERSION) \
		-t $(MARIA_IMAGE_NAME):latest \
		-f mariadb-backup/Dockerfile \
		.

clean-mariadb: ## Remove MariaDB Docker images
	docker rmi $(MARIA_IMAGE_NAME):$(MARIADB_VERSION) 2>/dev/null || true
	docker rmi $(MARIA_IMAGE_NAME):test 2>/dev/null || true
	docker rmi $(MARIA_IMAGE_NAME):latest 2>/dev/null || true

test-mariadb-db-up: ## Start the test MariaDB database
	docker compose -f mariadb-backup/compose.test.yml up -d

test-mariadb-db-down: ## Stop and remove the test MariaDB database
	docker compose -f mariadb-backup/compose.test.yml down -v

test-mariadb: ## Run the MariaDB backup test (requires test DB running)
	docker run --rm \
		--network host \
		-e DB_HOST=localhost \
		-e DB_PORT=3306 \
		-e DB_USER=root \
		-e DB_PASSWORD=testpass \
		-e DB_NAME=testdb \
		-e BACKUP_NAME=test_backup \
		-e SKIP_S3_UPLOAD=true \
		$(MARIA_IMAGE_NAME):$(MARIADB_VERSION)
