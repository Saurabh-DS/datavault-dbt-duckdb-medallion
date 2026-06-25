# DataVault Makefile
# On Windows: install make via `choco install make` or use WSL.
# All dbt commands pass --profiles-dir . to read profiles.yml from project root.

.PHONY: all full-run generate seed snapshot build test docs clean \
        airflow-up airflow-down airflow-logs airflow-restart help

# ── Default target ─────────────────────────────────────────────────────────────
all: help

# ── Full pipeline ──────────────────────────────────────────────────────────────
full-run: generate seed snapshot build test
	@echo "✅  DataVault full pipeline completed successfully."

# ── Individual steps ───────────────────────────────────────────────────────────
generate:
	@echo "⚙️   Generating synthetic UK motor insurance data..."
	python scripts/generate_data.py

seed:
	@echo "🌱  Loading seed data into DuckDB..."
	dbt seed --profiles-dir .

snapshot:
	@echo "📸  Running SCD snapshots..."
	dbt snapshot --profiles-dir .

build:
	@echo "🏗️   Building all dbt models..."
	dbt build --profiles-dir .

test:
	@echo "🧪  Running all dbt tests..."
	dbt test --profiles-dir .

compile:
	@echo "✏️   Compiling dbt project (no execution)..."
	dbt compile --profiles-dir .

# ── Scoped builds ─────────────────────────────────────────────────────────────
build-staging:
	dbt build --select staging --profiles-dir .

build-intermediate:
	dbt build --select intermediate --profiles-dir .

build-marts:
	dbt build --select marts --profiles-dir .

test-singular:
	dbt test --select test_type:singular --profiles-dir .

# ── Documentation ─────────────────────────────────────────────────────────────
docs: docs-generate docs-serve

docs-generate:
	@echo "📚  Generating dbt docs..."
	dbt docs generate --profiles-dir .

docs-serve:
	@echo "🌐  Opening dbt docs at http://localhost:8080"
	dbt docs serve --port 8080 --profiles-dir .

# ── Airflow (Docker Compose) ───────────────────────────────────────────────────
airflow-up:
	@echo "🚀  Starting Airflow stack..."
	@docker compose up airflow-init
	docker compose up -d
	@echo "✅  Airflow running at http://localhost:8080  (admin / admin)"

airflow-down:
	@echo "🛑  Stopping Airflow stack..."
	docker compose down

airflow-logs:
	docker compose logs -f airflow-scheduler airflow-webserver

airflow-restart:
	docker compose restart airflow-scheduler airflow-webserver

# ── Clean ──────────────────────────────────────────────────────────────────────
clean:
	@echo "🧹  Cleaning dbt artefacts..."
	dbt clean --profiles-dir .
	@rm -f datavault.duckdb datavault.duckdb.wal
	@echo "Done."

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "DataVault — available make targets:"
	@echo ""
	@echo "  make full-run          Run the complete pipeline end-to-end"
	@echo "  make generate          Generate synthetic seed CSVs"
	@echo "  make seed              dbt seed (load CSVs into DuckDB)"
	@echo "  make snapshot          dbt snapshot (SCD Type 1 and 2)"
	@echo "  make build             dbt build (all models + generic tests)"
	@echo "  make test              dbt test (all tests)"
	@echo "  make compile           Compile SQL without executing"
	@echo "  make build-staging     Build bronze layer only"
	@echo "  make build-intermediate Build silver layer only"
	@echo "  make build-marts       Build gold layer only"
	@echo "  make test-singular     Run custom singular tests only"
	@echo "  make docs              Generate and serve dbt docs"
	@echo "  make airflow-up        Start local Airflow stack (Docker)"
	@echo "  make airflow-down      Stop Airflow stack"
	@echo "  make airflow-logs      Tail Airflow scheduler + webserver logs"
	@echo "  make clean             Remove target/ and datavault.duckdb"
	@echo ""
