"""Реализация DBClient для Oracle (oracledb, thin mode)."""
from __future__ import annotations

from typing import Any, Sequence

import oracledb

# Активируем Thick-режим, чтобы избежать ошибок DPY-4010 при выполнении SQL-скриптов,
# содержащих двоеточия в строковых литералах (например, "00:00:00").
# Требуется, чтобы Oracle Instant Client был установлен и доступен в LD_LIBRARY_PATH. ви
#oracledb.init_oracle_client()

from utils.config import DBProfile
from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)


class OracleClient(DBClient):
    driver_name = "oracle"

    def __init__(self, profile: DBProfile, connect_timeout: int = 10):
        self.profile = profile
        self.connect_timeout = connect_timeout
        self._conn: oracledb.Connection | None = None

    def connect(self) -> None:
        dsn = oracledb.makedsn(
            self.profile.host,
            self.profile.port,
            service_name=self.profile.service_name,
        )
        log.info("Oracle connect → %s@%s", self.profile.user, dsn)
        self._conn = oracledb.connect(
            user=self.profile.user,
            password=self.profile.password,
            dsn=dsn,
            tcp_connect_timeout=self.connect_timeout,
        )
        # Сразу переключаем current_schema, чтобы объекты искались в нужной.
        if self.profile.schema_:
            with self._conn.cursor() as cur:
                cur.execute(f"ALTER SESSION SET CURRENT_SCHEMA = {self.profile.schema_}")

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
            cur.execute(sql, params or [])
        self._conn.commit()  # type: ignore[union-attr]

    def fetch_all(self, sql: str, params: Sequence[Any] | dict | None = None) -> list[tuple]:
        with self._cursor() as cur:
            cur.execute(sql, params or [])
            return cur.fetchall()

    def fetch_one(self, sql: str, params: Sequence[Any] | dict | None = None) -> tuple | None:
        with self._cursor() as cur:
            cur.execute(sql, params or [])
            return cur.fetchone()
