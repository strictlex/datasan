"""
Проверка наличия объектов в БД. Использует системные представления,
поэтому SQL разный на каждую СУБД — скрываем различия за одним интерфейсом.
"""
from __future__ import annotations

from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)


class SchemaInspector:
    def __init__(self, client: DBClient, schema: str):
        self.client = client
        self.schema = schema.upper() if client.driver_name == "oracle" else schema

    # ----- Oracle queries ----------------------------------------------------
    _ORA_TABLE = """
        SELECT COUNT(*) FROM all_tables
        WHERE owner = :owner AND table_name = :name
    """
    _ORA_PROC = """
        SELECT COUNT(*) FROM all_procedures
        WHERE owner = :owner AND object_name = :name
    """

    # ----- PostgreSQL queries ------------------------------------------------
    _PG_TABLE = """
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = %s AND table_name = %s
    """
    _PG_PROC = """
        SELECT COUNT(*) FROM information_schema.routines
        WHERE routine_schema = %s AND routine_name = %s
    """

    # ----- MSSQL queries -----------------------------------------------------
    _MS_TABLE = """
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s
    """
    _MS_PROC = """
        SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_SCHEMA = %s AND ROUTINE_NAME = %s
    """

    def table_exists(self, name: str) -> bool:
        drv = self.client.driver_name
        if drv == "oracle":
            n = self.client.fetch_scalar(
                self._ORA_TABLE, {"owner": self.schema, "name": name.upper()}
            )
        elif drv == "postgres":
            n = self.client.fetch_scalar(self._PG_TABLE, (self.schema, name))
        elif drv == "mssql":
            n = self.client.fetch_scalar(self._MS_TABLE, (self.schema, name))
        else:
            raise NotImplementedError(drv)
        exists = bool(n and int(n) > 0)
        log.debug("table_exists(%s.%s) → %s", self.schema, name, exists)
        return exists

    def procedure_exists(self, name: str) -> bool:
        drv = self.client.driver_name
        if drv == "oracle":
            n = self.client.fetch_scalar(
                self._ORA_PROC, {"owner": self.schema, "name": name.upper()}
            )
        elif drv == "postgres":
            n = self.client.fetch_scalar(self._PG_PROC, (self.schema, name))
        elif drv == "mssql":
            n = self.client.fetch_scalar(self._MS_PROC, (self.schema, name))
        else:
            raise NotImplementedError(drv)
        exists = bool(n and int(n) > 0)
        log.debug("procedure_exists(%s.%s) → %s", self.schema, name, exists)
        return exists

    def assert_objects(self, *, tables: list[str] | None = None,
                       procedures: list[str] | None = None) -> list[str]:
        """
        Проверяет список ожидаемых объектов. Возвращает список отсутствующих
        (пустой список == всё на месте).
        """
        missing: list[str] = []
        for t in tables or []:
            if not self.table_exists(t):
                missing.append(f"table:{t}")
        for p in procedures or []:
            if not self.procedure_exists(p):
                missing.append(f"procedure:{p}")
        return missing
