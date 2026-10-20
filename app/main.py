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
