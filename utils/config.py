"""
Загрузка конфигурации из YAML + .env.

Схема валидируется pydantic-моделями, секреты подставляются из окружения
через синтаксис ${VAR_NAME}.
"""
from __future__ import annotations

import os
import re
from pathlib import Path
from typing import Literal

import yaml
from dotenv import load_dotenv
from pydantic import BaseModel, Field

ROOT_DIR = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT_DIR / "config" / "databases.yaml"

_ENV_PATTERN = re.compile(r"\$\{([A-Z0-9_]+)\}")


def _interpolate(value: object) -> object:
    """Рекурсивно подставляет ${VAR} из окружения в строковые значения."""
    if isinstance(value, str):
        def repl(m: re.Match[str]) -> str:
            var = m.group(1)
            env_val = os.getenv(var)
            if env_val is None:
                raise RuntimeError(
                    f"Переменная окружения {var} не задана. "
                    f"Проверь .env или экспорт в шелле."
                )
            return env_val
        return _ENV_PATTERN.sub(repl, value)
    if isinstance(value, dict):
        return {k: _interpolate(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_interpolate(v) for v in value]
    return value


class DBProfile(BaseModel):
    driver: Literal["oracle", "postgres", "mssql"]
    host: str
    port: int
    user: str
    password: str
    schema_: str = Field(alias="schema")
    sql_dir: str
    statement_separator: str = ";"
    # опциональные, зависят от СУБД
    database: str | None = None       # postgres/mssql
    service_name: str | None = None   # oracle

    model_config = {"populate_by_name": True}

    @property
    def sql_dir_abs(self) -> Path:
        return ROOT_DIR / self.sql_dir


class RunConfig(BaseModel):
    connect_timeout_sec: int = 10
    query_timeout_sec: int = 300
    cleanup_on_teardown: bool = True


class AppConfig(BaseModel):
    databases: dict[str, DBProfile]
    run: RunConfig


def load_config(db_key: str | None = None) -> AppConfig:
    """Загружает конфиг. .env читается один раз."""
    load_dotenv(ROOT_DIR / ".env", override=False)

    with CONFIG_PATH.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f)

    # Интерполируем только тот профиль, который реально выбран, —
    # иначе .env будет обязан содержать переменные для всех СУБД сразу.
    if db_key:
        if db_key not in raw.get("databases", {}):
            raise ValueError(
                f"Профиль '{db_key}' не найден в {CONFIG_PATH}. "
                f"Доступны: {list(raw['databases'])}"
            )
        raw["databases"] = {db_key: _interpolate(raw["databases"][db_key])}
    else:
        raw["databases"] = _interpolate(raw["databases"])

    return AppConfig(**raw)
