"""Реализация DBClient для PostgreSQL (psycopg 3)."""
from __future__ import annotations

from typing import Any, Sequence

import psycopg

from utils.config import DBProfile
from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)


class PostgresClient(DBClient):
    driver_name = "postgres"

    def __init__(self, profile: DBProfile, connect_timeout: int = 10):
        self.profile = profile
        self.connect_timeout = connect_timeout
        self._conn: psycopg.Connection | None = None

    def connect(self) -> None:
        log.info(
            "Postgres connect → %s@%s:%s/%s",
            self.profile.user, self.profile.host, self.profile.port, self.profile.database,
        )
        self._conn = psycopg.connect(
            host=self.profile.host,
            port=self.profile.port,
            dbname=self.profile.database,
            user=self.profile.user,
            password=self.profile.password,
            connect_timeout=self.connect_timeout,
            autocommit=False,
        )
        if self.profile.schema_:
            with self._conn.cursor() as cur:
                cur.execute(f"SET search_path TO {self.profile.schema_}")
            self._conn.commit()

    def close(self) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None

    def _cursor(self):
        if self._conn is None:
            raise RuntimeError("Соединение не установлено, вызови connect()")
        return self._conn.cursor()

    def execute(self, sql: str, params: Sequence[Any] | dict | None = None) -> None:
        with self._cursor() as cur:
            cur.execute(sql, params)
        self._conn.commit()  # type: ignore[union-attr]

    def fetch_all(self, sql, params=None):
        with self._cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchall()

    def fetch_one(self, sql, params=None):
        with self._cursor() as cur:
            cur.execute(sql, params)
            return cur.fetchone()
