"""
Абстрактный клиент СУБД. Все конкретные реализации обязаны
поддерживать один и тот же контракт, чтобы тесты не знали о различиях.
"""
from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any, Sequence


class DBClient(ABC):
    """Тонкая обёртка над DB-API 2.0 с унифицированной поверхностью."""

    driver_name: str = "abstract"

    @abstractmethod
    def connect(self) -> None: ...

    @abstractmethod
    def close(self) -> None: ...

    @abstractmethod
    def execute(self, sql: str, params: Sequence[Any] | dict | None = None) -> None:
        """Выполнить statement без возврата данных (DDL/DML)."""

    @abstractmethod
    def fetch_all(self, sql: str, params: Sequence[Any] | dict | None = None) -> list[tuple]:
        """Вернуть все строки результата SELECT."""

    @abstractmethod
    def fetch_one(self, sql: str, params: Sequence[Any] | dict | None = None) -> tuple | None: ...

    def fetch_scalar(self, sql: str, params: Sequence[Any] | dict | None = None) -> Any:
        row = self.fetch_one(sql, params)
        return row[0] if row else None

    def __enter__(self) -> "DBClient":
        self.connect()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()
