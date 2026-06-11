"""
Массовое тестирование одного метода маскирования на таблице с ~100k строк.
Поддерживает Oracle, PostgreSQL, MS SQL Server.
"""
from __future__ import annotations

import csv
import random
from pathlib import Path
from typing import Callable, Any

from utils.db.base import DBClient
from utils.data_factory import GENERATORS
from utils.validators import always_changed
from utils.logger import get_logger

log = get_logger(__name__)

# Словарь валидаторов (можно расширять)
VALIDATORS = {
    "inn_12": __import__("utils.validators").validators.valid_inn,
    "snils": __import__("utils.validators").validators.valid_snils,
    "phone": __import__("utils.validators").validators.valid_phone,
    "passport": __import__("utils.validators").validators.valid_passport,
    "ip": __import__("utils.validators").validators.valid_ip,
    "ogrn": __import__("utils.validators").validators.valid_ogrn,
    "cardnumber": __import__("utils.validators").validators.valid_cardnumber,
    "date": __import__("utils.validators").validators.valid_date,
    "always_changed": always_changed,
}
# Подгрузим остальные валидаторы из модуля
from utils.validators import (
    valid_inn, valid_snils, valid_phone, valid_passport, valid_ip,
    valid_ogrn, valid_cardnumber, valid_date
)
VALIDATORS.update({
    "inn_12": valid_inn,
    "snils": valid_snils,
    "phone": valid_phone,
    "passport": valid_passport,
    "ip": valid_ip,
    "ogrn": valid_ogrn,
    "cardnumber": valid_cardnumber,
    "date": valid_date,
})


class MethodTester:
    def __init__(self, client: DBClient, method_config: dict):
        self.client = client
        self.method_name = method_config["function"]
        self.data_type = method_config.get("data_type", "VARCHAR2")
        self.generator_key = method_config["generator"]
        self.validator_key = method_config.get("validator", "always_changed")
        self.description = method_config.get("description", "")

        # Получаем генераторы
        gen_correct, gen_incorrect = GENERATORS[self.generator_key]
        self.gen_correct = gen_correct
        self.gen_incorrect = gen_incorrect

        # Получаем валидатор
        self.validator = VALIDATORS.get(self.validator_key, always_changed)
        if self.validator is always_changed and self.validator_key != "always_changed":
            log.warning(f"Валидатор '{self.validator_key}' не найден, использую always_changed")

        # Уникальное имя таблицы для этого теста
        import uuid
        self.table_name = f"TMP_MASK_{uuid.uuid4().hex[:8]}".upper()

    def _ddl(self) -> str:
        """Возвращает CREATE TABLE с учётом драйвера."""
        drv = self.client.driver_name
        if drv == "oracle":
            # Oracle: NUMBER, VARCHAR2, DATE
            if self.data_type == "NUMBER":
                col_def = "original_value NUMBER"
            elif self.data_type == "DATE":
                col_def = "original_value DATE"
            else:
                col_def = "original_value VARCHAR2(4000)"
            return f"""
                CREATE TABLE {self.table_name} (
                    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                    {col_def},
                    masked_value VARCHAR2(4000),
                    is_valid NUMBER(1)
                )
            """
        elif drv == "postgres":
            if self.data_type == "NUMBER":
                col_def = "original_value NUMERIC"
            elif self.data_type == "DATE":
                col_def = "original_value DATE"
            else:
                col_def = "original_value TEXT"
            return f"""
                CREATE TABLE {self.table_name} (
                    id SERIAL PRIMARY KEY,
                    {col_def},
                    masked_value TEXT,
                    is_valid INTEGER
                )
            """
        elif drv == "mssql":
            if self.data_type == "NUMBER":
                col_def = "original_value NUMERIC"
            elif self.data_type == "DATE":
                col_def = "original_value DATE"
            else:
                col_def = "original_value NVARCHAR(4000)"
            return f"""
                CREATE TABLE {self.table_name} (
                    id INT IDENTITY(1,1) PRIMARY KEY,
                    {col_def},
                    masked_value NVARCHAR(4000),
                    is_valid INT
                )
            """
        else:
            raise NotImplementedError(drv)

    def _insert_sql(self) -> str:
        drv = self.client.driver_name
        if drv == "oracle":
            if self.data_type == "DATE":
                # Для Oracle используем TO_DATE с форматом
                return f"INSERT INTO {self.table_name} (original_value) VALUES (TO_DATE(:1, 'YYYY-MM-DD'))"
            else:
                return f"INSERT INTO {self.table_name} (original_value) VALUES (:1)"
        else:
            # Postgres/MSSQL могут принимать строку 'YYYY-MM-DD' как DATE
            return f"INSERT INTO {self.table_name} (original_value) VALUES (%s)"
    

    def create_table(self) -> None:
        """Создаёт временную таблицу."""
        self.client.execute(self._ddl())
        log.info("Создана таблица %s", self.table_name)

    def drop_table(self) -> None:
        """Удаляет таблицу (если существует)."""
        drv = self.client.driver_name
        try:
            if drv == "oracle":
                self.client.execute(f"DROP TABLE {self.table_name} PURGE")
            elif drv == "postgres":
                self.client.execute(f"DROP TABLE IF EXISTS {self.table_name}")
            elif drv == "mssql":
                self.client.execute(f"IF OBJECT_ID('{self.table_name}', 'U') IS NOT NULL DROP TABLE {self.table_name}")
        except Exception as e:
            log.warning("Не удалось удалить таблицу %s: %s", self.table_name, e)

    def populate(self, rows: int = 100000, null_ratio: float = 0.1, incorrect_ratio: float = 0.45) -> None:
        """
        Заполняет таблицу случайными данными.
        - null_ratio: доля NULL
        - incorrect_ratio: доля некорректных данных среди ненулевых
        """
        rng = random.Random(42)  # детерминированность
        sql = self._insert_sql()
        batch = []
        batch_size = 500

        for i in range(rows):
            if rng.random() < null_ratio:
                value = None
            else:
                if rng.random() < incorrect_ratio:
                    value = self.gen_incorrect(rng)
                else:
                    value = self.gen_correct(rng)
            batch.append((value,))
            if len(batch) >= batch_size:
                for val in batch:
                    self.client.execute(sql, val)
                batch.clear()
        # остатки
        for val in batch:
            self.client.execute(sql, val)

        log.info("Таблица %s заполнена %d строками", self.table_name, rows)

    def apply_masking(self) -> None:
        """Выполняет UPDATE, присваивая masked_value = функция(original_value)."""
        drv = self.client.driver_name
        # Для Oracle имена функций в верхнем регистре
        func_name = self.method_name.upper()
        if drv == "oracle":
            # Для DATE нужно возможно обернуть в TO_DATE? Нет, функция принимает DATE
            update_sql = f"""
                UPDATE {self.table_name}
                SET masked_value = {func_name}(original_value)
                WHERE original_value IS NOT NULL
            """
        else:
            # Postgres/MSSQL – вызов функции как есть
            update_sql = f"""
                UPDATE {self.table_name}
                SET masked_value = {func_name}(original_value)
                WHERE original_value IS NOT NULL
            """
        self.client.execute(update_sql)
        # Для NULL оставляем NULL
        self.client.execute(f"UPDATE {self.table_name} SET masked_value = NULL WHERE original_value IS NULL")
        log.info("Маскирование применено к таблице %s", self.table_name)

    def validate(self) -> tuple[int, int, list[dict]]:
        """
        Проверяет каждую строку, заполняет is_valid и возвращает статистику.
        Возвращает (total, passed, failed_rows) где failed_rows – список словарей с деталями.
        """
        drv = self.client.driver_name
        # Выбираем все строки
        rows = self.client.fetch_all(f"SELECT id, original_value, masked_value FROM {self.table_name}")
        total = len(rows)
        passed = 0
        failed_rows = []

        for row in rows:
            row_id, original, masked = row
            # Для Oracle дата может прийти как datetime, приводим к строке для валидатора
            if self.data_type == "DATE" and original is not None:
                original_str = original.strftime("%Y-%m-%d") if hasattr(original, "strftime") else str(original)
                masked_str = masked.strftime("%Y-%m-%d") if hasattr(masked, "strftime") else str(masked) if masked else None
            else:
                original_str = str(original) if original is not None else None
                masked_str = str(masked) if masked is not None else None

            if original is None:
                is_ok = (masked is None)
            else:
                # Для проверки формата передаём маскированное значение, но валидатор может ожидать строку
                if self.validator_key in ("always_changed",):
                    is_ok = self.validator(original_str, masked_str)
                else:
                    # Для валидаторов формата передаём только masked_str
                    is_ok = self.validator(masked_str)
            if is_ok:
                passed += 1
                valid_flag = 1
            else:
                valid_flag = 0
                failed_rows.append({
                    "id": row_id,
                    "original": original_str,
                    "masked": masked_str,
                    "validator": self.validator_key,
                })
            # Обновляем is_valid в таблице (опционально, для отладки)
            self.client.execute(
                f"UPDATE {self.table_name} SET is_valid = %s WHERE id = %s" if drv != "oracle"
                else f"UPDATE {self.table_name} SET is_valid = :1 WHERE id = :2",
                (valid_flag, row_id)
            )
        return total, passed, failed_rows

    def save_report(self, report_path: Path, failed_rows: list[dict]) -> None:
        """Сохраняет CSV-отчёт с неудавшимися строками и общей статистикой."""
        report_path.parent.mkdir(parents=True, exist_ok=True)
        with open(report_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f, delimiter="|")
            writer.writerow(["Method", self.method_name])
            writer.writerow(["Description", self.description])
            writer.writerow(["Generator", self.generator_key])
            writer.writerow(["Validator", self.validator_key])
            writer.writerow(["Failed rows", len(failed_rows)])
            writer.writerow([])
            writer.writerow(["id", "original", "masked", "validator"])
            for row in failed_rows:
                writer.writerow([row["id"], row["original"], row["masked"], row["validator"]])
        log.info("Отчёт сохранён: %s", report_path)

    def run(self, rows: int = 100000, report_dir: Path | None = None) -> bool:
        """
        Запускает полный цикл тестирования.
        Возвращает True, если все строки прошли валидацию.
        """
        self.create_table()
        try:
            self.populate(rows)
            self.apply_masking()
            total, passed, failed = self.validate()
            success_rate = passed / total if total else 0
            log.info("Метод %s: обработано %d строк, успешно %d (%.2f%%)",
                     self.method_name, total, passed, success_rate * 100)

            if report_dir:
                report_path = report_dir / f"scale_{self.method_name}.csv"
                self.save_report(report_path, failed)

            return passed == total
        finally:
            self.drop_table()