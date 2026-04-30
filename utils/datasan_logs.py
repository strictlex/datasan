"""
Чтение логов DataSan из таблицы PFLB_LOGS.

DataSan пишет свои логи в БД, а не в файл, поэтому многие тесты проверяют именно содержимое этой таблицы.
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from utils.db.base import DBClient


@dataclass(frozen=True)
class LogEntry:
    log_id: int
    log_time: datetime
    log_level: str
    message: str


class DatasanLogReader:
    """Читает PFLB_LOGS. Предполагаем стандартную схему DataSan."""

    def __init__(self, client: DBClient, table: str = "pflb_logs"):
        self.client = client
        self.table = table

    def latest(self, limit: int = 50) -> list[LogEntry]:
        drv = self.client.driver_name
        if drv == "oracle":
            sql = (f"SELECT log_id, log_time, log_level, message "
                   f"FROM {self.table} ORDER BY log_id DESC FETCH FIRST :n ROWS ONLY")
            rows = self.client.fetch_all(sql, {"n": limit})
        elif drv == "postgres":
            sql = (f"SELECT log_id, log_time, log_level, message "
                   f"FROM {self.table} ORDER BY log_id DESC LIMIT %s")
            rows = self.client.fetch_all(sql, (limit,))
        elif drv == "mssql":
            sql = (f"SELECT TOP (%s) log_id, log_time, log_level, message "
                   f"FROM {self.table} ORDER BY log_id DESC")
            rows = self.client.fetch_all(sql, (limit,))
        else:
            raise NotImplementedError(drv)
        return [LogEntry(*r) for r in rows]

    def contains(self, substring: str, *, level: str | None = None,
                 limit: int = 200) -> bool:
        """Есть ли в последних `limit` записях сообщение, содержащее substring."""
        for entry in self.latest(limit):
            if level and entry.log_level != level:
                continue
            if substring in (entry.message or ""):
                return True
        return False

    def count(self) -> int:
        return int(self.client.fetch_scalar(f"SELECT COUNT(*) FROM {self.table}") or 0)
