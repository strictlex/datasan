"""Реализация DBClient для MS SQL Server (pymssql)."""
from __future__ import annotations

from typing import Any, Sequence

import pymssql

from utils.config import DBProfile
from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)


class MSSQLClient(DBClient):
    driver_name = "mssql"

    def __init__(self, profile: DBProfile, connect_timeout: int = 10):
        self.profile = profile
        self.connect_timeout = connect_timeout
        self._conn = None

    def connect(self) -> None:
        log.info(
            "MSSQL connect → %s@%s:%s/%s",
            self.profile.user, self.profile.host, self.profile.port, self.profile.database,
        )
        self._conn = pymssql.connect(
            server=self.profile.host,
            port=str(self.profile.port),
            database=self.profile.database,
            user=self.profile.user,
            password=self.profile.password,
            login_timeout=self.connect_timeout,
            autocommit=False,
        )
        # В MSSQL схема задаётся на уровне объекта (dbo.table), менять default-схему
        # юзера через ALTER USER требует прав; оставляем работу со схемой тестам.

    def close(self) -> None:
        if self._conn is not None:
            self._conn.close()
            self._conn = None

    def _cursor(self):
        if self._conn is None:
            raise RuntimeError("Соединение не установлено, вызови connect()")
        return self._conn.cursor()

    def execute(self, sql: str, params: Sequence[Any] | dict | None = None) -> None:
        cur = self._cursor()
        try:
            cur.execute(sql, params)
            self._conn.commit()
        finally:
            cur.close()

    def fetch_all(self, sql, params=None):
        cur = self._cursor()
        try:
            cur.execute(sql, params)
            return cur.fetchall()
        finally:
            cur.close()

    def fetch_one(self, sql, params=None):
        cur = self._cursor()
        try:
            cur.execute(sql, params)
            return cur.fetchone()
        finally:
            cur.close()
