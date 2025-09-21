# AnalystAI Backend Makefile

# Variables
PROJECT_ID ?= $(shell grep GOOGLE_PROJECT_ID .env | cut -d '=' -f2)
REGION ?= us-central1
SERVICE_NAME = analystai-backend
IMAGE_NAME = gcr.io/$(PROJECT_ID)/$(SERVICE_NAME)
VERSION ?= latest
PYTHON = python3.12
VENV = venv
PORT ?= 8080

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(GREEN)AnalystAI Backend - Available Commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

.PHONY: setup
setup: ## Set up virtual environment and install dependencies
	@echo "$(GREEN)Setting up virtual environment...$(NC)"
	$(PYTHON) -m venv $(VENV)
	. $(VENV)/bin/activate && pip install --upgrade pip
	. $(VENV)/bin/activate && pip install -r requirements.txt
	@echo "$(GREEN)Setup complete! Activate with: source $(VENV)/bin/activate$(NC)"

.PHONY: install
install: ## Install dependencies in existing virtual environment
	@echo "$(GREEN)Installing dependencies...$(NC)"
	. $(VENV)/bin/activate && pip install -r requirements.txt

.PHONY: run
run: ## Run the application locally
	@echo "$(GREEN)Starting AnalystAI Backend on port $(PORT)...$(NC)"
	. $(VENV)/bin/activate && python -m uvicorn app.main:app --reload --host 0.0.0.0 --port $(PORT)

.PHONY: run-prod
run-prod: ## Run the application in production mode
	@echo "$(GREEN)Starting AnalystAI Backend in production mode...$(NC)"
	. $(VENV)/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port $(PORT)

.PHONY: test
test: ## Run unit tests
	@echo "$(GREEN)Running tests...$(NC)"
	. $(VENV)/bin/activate && pytest tests/ -v --cov=app --cov-report=term-missing

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report
	@echo "$(GREEN)Running tests with coverage...$(NC)"
	. $(VENV)/bin/activate && pytest tests/ -v --cov=app --cov-report=html --cov-report=term
	@echo "$(GREEN)Coverage report generated in htmlcov/index.html$(NC)"

.PHONY: lint
lint: ## Run code linting
	@echo "$(GREEN)Running linters...$(NC)"
	. $(VENV)/bin/activate && ruff check app/ tests/
	. $(VENV)/bin/activate && mypy app/ --ignore-missing-imports

.PHONY: format
format: ## Format code with black
	@echo "$(GREEN)Formatting code...$(NC)"
	. $(VENV)/bin/activate && black app/ tests/

.PHONY: clean
clean: ## Clean up generated files
	@echo "$(GREEN)Cleaning up...$(NC)"
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	rm -rf htmlcov/ .coverage .pytest_cache/ .mypy_cache/
	rm -rf logs/*.log data/uploads/* data/reports/* data/exports/*

.PHONY: build
build: ## Build Docker image
	@echo "$(GREEN)Building Docker image: $(IMAGE_NAME):$(VERSION)$(NC)"
	docker build -t $(IMAGE_NAME):$(VERSION) .
	docker tag $(IMAGE_NAME):$(VERSION) $(IMAGE_NAME):latest

.PHONY: build-no-cache
build-no-cache: ## Build Docker image without cache
	@echo "$(GREEN)Building Docker image without cache...$(NC)"
	docker build --no-cache -t $(IMAGE_NAME):$(VERSION) .

.PHONY: docker-run
docker-run: build ## Run Docker container locally
	@echo "$(GREEN)Running Docker container...$(NC)"
	docker run --rm -p $(PORT):8080 \
		--env-file .env \
		--name $(SERVICE_NAME) \
		$(IMAGE_NAME):$(VERSION)

.PHONY: docker-shell
docker-shell: ## Open shell in Docker container
	@echo "$(GREEN)Opening shell in container...$(NC)"
	docker run --rm -it \
		--env-file .env \
		--entrypoint /bin/bash \
		$(IMAGE_NAME):$(VERSION)

.PHONY: docker-push
docker-push: ## Push Docker image to registry
	@echo "$(GREEN)Pushing image to registry...$(NC)"
	docker push $(IMAGE_NAME):$(VERSION)
	docker push $(IMAGE_NAME):latest

.PHONY: deploy
deploy: build docker-push ## Deploy to Google Cloud Run
	@echo "$(GREEN)Deploying to Cloud Run...$(NC)"
	gcloud run deploy $(SERVICE_NAME) \
		--image $(IMAGE_NAME):$(VERSION) \
		--platform managed \
		--region $(REGION) \
		--allow-unauthenticated \
		--port 8080 \
		--memory 2Gi \
		--cpu 2 \
		--max-instances 10 \
		--min-instances 1 \
		--set-env-vars "GOOGLE_PROJECT_ID=$(PROJECT_ID),GOOGLE_LOCATION=$(REGION)" \
		--project $(PROJECT_ID)
	@echo "$(GREEN)Deployment complete!$(NC)"

.PHONY: deploy-with-secrets
deploy-with-secrets: build docker-push ## Deploy with Secret Manager
	@echo "$(GREEN)Deploying with secrets from Secret Manager...$(NC)"
	gcloud run deploy $(SERVICE_NAME) \
		--image $(IMAGE_NAME):$(VERSION) \
		--platform managed \
		--region $(REGION) \
		--allow-unauthenticated \
		--port 8080 \
		--memory 2Gi \
		--cpu 2 \
		--max-instances 10 \
		--min-instances 1 \
		--set-env-vars "GOOGLE_PROJECT_ID=$(PROJECT_ID),GOOGLE_LOCATION=$(REGION)" \
		--set-secrets "API_KEY=api-key:latest" \
		--project $(PROJECT_ID)

.PHONY: logs
logs: ## View Cloud Run logs
	@echo "$(GREEN)Fetching Cloud Run logs...$(NC)"
	gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=$(SERVICE_NAME)" \
		--limit 50 \
		--project $(PROJECT_ID) \
		--format "table(timestamp,severity,textPayload)"

.PHONY: describe
describe: ## Describe Cloud Run service
	@echo "$(GREEN)Service details:$(NC)"
	gcloud run services describe $(SERVICE_NAME) \
		--platform managed \
		--region $(REGION) \
		--project $(PROJECT_ID)

.PHONY: url
url: ## Get service URL
	@echo "$(GREEN)Service URL:$(NC)"
	@gcloud run services describe $(SERVICE_NAME) \
		--platform managed \
		--region $(REGION) \
		--project $(PROJECT_ID) \
		--format 'value(status.url)'

.PHONY: health-check
health-check: ## Check service health
	@echo "$(GREEN)Checking service health...$(NC)"
	@URL=$$(gcloud run services describe $(SERVICE_NAME) \
		--platform managed \
		--region $(REGION) \
		--project $(PROJECT_ID) \
		--format 'value(status.url)'); \
	curl -s $$URL/health | python -m json.tool

.PHONY: create-secrets
create-secrets: ## Create secrets in Secret Manager
	@echo "$(GREEN)Creating secrets in Secret Manager...$(NC)"
	@read -p "Enter API Key: " api_key; \
	echo -n "$$api_key" | gcloud secrets create api-key \
		--data-file=- \
		--replication-policy="automatic" \
		--project $(PROJECT_ID) || true

.PHONY: env-template
env-template: ## Create .env file from template
	@echo "$(GREEN)Creating .env file from template...$(NC)"
	@if [ ! -f .env ]; then \
		echo "# AnalystAI Backend Environment Variables" > .env; \
		echo "GOOGLE_PROJECT_ID=your-project" >> .env; \
		echo "GOOGLE_LOCATION=us-central1" >> .env; \
		echo "GCP_BUCKET=analystai-raw" >> .env; \
		echo "USE_VERTEX=false" >> .env; \
		echo "USE_MATCHING_ENGINE=false" >> .env; \
		echo "USE_BIGQUERY=false" >> .env; \
		echo "GEMINI_MODEL=gemini-1.5-pro" >> .env; \
		echo "EMBED_MODEL=text-embedding-004" >> .env; \
		echo "API_KEY=dev-secret" >> .env; \
		echo "HOST=0.0.0.0" >> .env; \
		echo "PORT=8080" >> .env; \
		echo "LOG_LEVEL=INFO" >> .env; \
		echo "$(GREEN).env file created! Please update with your values.$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists$(NC)"; \
	fi

.PHONY: all
all: setup lint test build ## Run setup, lint, test, and build
