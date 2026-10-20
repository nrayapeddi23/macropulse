
#!/usr/bin/env bash
set -euo pipefail

# Run from the macropulse project root.
mkdir -p \
  app/api/routes app/core app/db app/schemas app/services app/ml \
  etl/clients dags notebooks migrations tests scripts artifacts

# Make Python directories importable.
for dir in app app/api app/api/routes app/core app/db \
  app/schemas app/services app/ml etl etl/clients scripts; do
  touch "$dir/__init__.py"
done

# Create the full project skeleton.
files=(
  app/api/routes/health.py
  app/api/routes/observations.py
  app/api/routes/forecasts.py
  app/api/routes/models.py
  app/core/config.py
  app/db/session.py
  app/db/models.py
  app/schemas/observation.py
  app/schemas/forecast.py
  app/services/data_service.py
  app/services/forecast_service.py
  app/ml/features.py
  app/ml/train.py
  app/ml/evaluate.py
  app/ml/predict.py
  etl/clients/fred.py
  etl/clients/eia.py
  etl/clients/world_bank.py
  etl/extract.py
  etl/transform.py
  etl/validate.py
  etl/load.py
  dags/macropulse_pipeline.py
  migrations/.gitkeep
  notebooks/.gitkeep
  tests/test_etl.py
  tests/test_features.py
  tests/test_api.py
  tests/test_database.py
  scripts/ingest.py
  scripts/train_model.py
  artifacts/.gitkeep
  alembic.ini
)

for file in "${files[@]}"; do
  touch "$file"
done

# Application settings.
cat > app/core/config.py <<'EOF'
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "MacroPulse"
    database_url: str = "sqlite:///./macropulse.db"
    fred_api_key: str = ""
    eia_api_key: str = ""

    model_config = SettingsConfigDict(
        env_file=".env",
        extra="ignore",
    )


settings = Settings()
EOF

# Database engine. SQLite works locally; PostgreSQL can be
# configured later using DATABASE_URL.
cat > app/db/session.py <<'EOF'
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.core.config import settings

connect_args = (
    {"check_same_thread": False}
    if settings.database_url.startswith("sqlite")
    else {}
)

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    autocommit=False,
)


class Base(DeclarativeBase):
    pass
EOF

# Minimal API endpoint.
cat > app/api/routes/health.py <<'EOF'
from fastapi import APIRouter

router = APIRouter(tags=["Health"])


@router.get("/health")
def health_check():
    return {"status": "ok", "service": "macropulse"}
EOF

cat > app/main.py <<'EOF'
from fastapi import FastAPI

from app.api.routes import health

app = FastAPI(
    title="MacroPulse API",
    description="Macroeconomic data ingestion and forecasting platform",
    version="0.1.0",
)

app.include_router(health.router, prefix="/api/v1")


@app.get("/")
def root():
    return {
        "message": "Welcome to MacroPulse",
        "docs": "/docs",
    }
EOF

# Dependencies and developer tools.
cat > pyproject.toml <<'EOF'
[project]
name = "macropulse"
version = "0.1.0"
description = "Macroeconomic data ingestion, analysis, and forecasting"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "pydantic-settings>=2.0",
    "sqlalchemy>=2.0",
    "psycopg[binary]>=3.2",
    "alembic>=1.13",
    "pandas>=2.2",
    "numpy>=1.26",
    "scikit-learn>=1.5",
    "httpx>=0.27",
    "requests>=2.32",
    "python-dotenv>=1.0",
]

[dependency-groups]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.6",
    "jupyterlab>=4.0",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["."]

[tool.ruff]
line-length = 88
EOF

cat > .env.example <<'EOF'
APP_NAME=MacroPulse
DATABASE_URL=sqlite:///./macropulse.db
FRED_API_KEY=
EIA_API_KEY=
EOF

cat > .gitignore <<'EOF'
.env
.venv/
__pycache__/
*.py[cod]
.pytest_cache/
.ruff_cache/
.ipynb_checkpoints/
.DS_Store
*.db
artifacts/*
!artifacts/.gitkeep
data/raw/*
data/processed/*
!data/raw/.gitkeep
!data/processed/.gitkeep
EOF

mkdir -p data/raw data/processed
touch data/raw/.gitkeep data/processed/.gitkeep

cat > Dockerfile <<'EOF'
FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir uv

COPY pyproject.toml ./
RUN uv sync --no-dev

COPY app ./app

EXPOSE 8000

CMD ["uv", "run", "--no-sync", "uvicorn", \
     "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

cat > docker-compose.yml <<'EOF'
services:
  api:
    build: .
    ports:
      - "8000:8000"
    env_file:
      - .env
    environment:
      DATABASE_URL: postgresql+psycopg://macropulse:macropulse@db:5432/macropulse
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: macropulse
      POSTGRES_PASSWORD: macropulse
      POSTGRES_DB: macropulse
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U macropulse -d macropulse"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  postgres_data:
EOF

cat > README.md <<'EOF'
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
EOF

echo "MacroPulse skeleton created."
