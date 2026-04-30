"""Фабрика DBClient по ключу профиля."""
from __future__ import annotations

from utils.config import DBProfile
from utils.db.base import DBClient


def make_client(profile: DBProfile, connect_timeout: int = 10) -> DBClient:
    # Импорты внутри, чтобы не тянуть драйверы всех СУБД, когда нужен только один.
    if profile.driver == "oracle":
        from utils.db.oracle import OracleClient
        return OracleClient(profile, connect_timeout=connect_timeout)
    if profile.driver == "postgres":
        from utils.db.postgres import PostgresClient
        return PostgresClient(profile, connect_timeout=connect_timeout)
    if profile.driver == "mssql":
        from utils.db.mssql import MSSQLClient
        return MSSQLClient(profile, connect_timeout=connect_timeout)
    raise ValueError(f"Неизвестный драйвер: {profile.driver}")
