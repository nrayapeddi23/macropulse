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
