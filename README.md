# MacroPulse

A macroeconomic data platform for collecting economic indicators,
storing observations, analyzing trends, and building forecasting models.

## Initial stack

- Python, pandas, scikit-learn
- FastAPI
- SQLAlchemy and PostgreSQL
- pytest and Ruff
- Docker Compose

## Local development

1. Install dependencies with `uv sync --group dev`.
2. Copy `.env.example` to `.env`.
3. Start the API with `uv run uvicorn app.main:app --reload`.
4. Open http://127.0.0.1:8000/docs.

The default local database is SQLite. Docker Compose configures
PostgreSQL for container-based development.

## Planned pipeline

Extract → Transform → Validate → Load → Feature Engineering
→ Train → Evaluate → Forecast API.

Airflow orchestration will be added after the initial pipeline works.
