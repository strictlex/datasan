"""
Фабрика тестовых данных.

Задача — быстро поднять временную таблицу с колонками ПДн (ИНН, телефон,
паспорт, ФИО) и наполнить её детерминированными синтетическими значениями.
Используется в SM-04, SM-05, SM-07, SM-08 и во всём регрессе профилирования.

Детерминированность важна: random.seed(42) гарантирует, что прогоны на
разных машинах сгенерируют одинаковые данные — это критично для сравнения
до/после обезличивания.
"""
from __future__ import annotations

import random
from dataclasses import dataclass
from typing import Callable

from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)


# ---------- Генераторы синтетических ПДн -------------------------------------
# ВАЖНО: это заведомо синтетика, не настоящие ПДн. ИНН валиден по контрольной
# сумме, чтобы проходить регулярки DataSan, но физически такого человека нет.

_FIRST_NAMES = ["Иван", "Мария", "Алексей", "Елена", "Дмитрий",
                "Ольга", "Сергей", "Анна", "Николай", "Татьяна"]
_LAST_NAMES = ["Иванов", "Петров", "Сидоров", "Кузнецов", "Смирнов",
               "Попов", "Васильев", "Соколов", "Михайлов", "Новиков"]


def inn_12(rng: random.Random) -> str:
    """Генерирует валидный 12-значный ИНН физлица (с корректными контрольными цифрами)."""
    digits = [rng.randint(0, 9) for _ in range(10)]
    # 11-я контрольная
    w1 = [7, 2, 4, 10, 3, 5, 9, 4, 1, 3]
    n11 = sum(d * w for d, w in zip(digits, w1)) % 11 % 10
    # 12-я контрольная
    w2 = [3, 7, 2, 4, 10, 3, 5, 9, 4, 1, 3]
    n12 = sum(d * w for d, w in zip(digits + [n11], w2)) % 11 % 10
    return "".join(map(str, digits + [n11, n12]))


def phone_ru(rng: random.Random) -> str:
    """+7 9XX XXX-XX-XX в формате '+7XXXXXXXXXX'."""
    return "+79" + "".join(str(rng.randint(0, 9)) for _ in range(9))


def passport_ru(rng: random.Random) -> str:
    """Серия + номер паспорта РФ: '1234 567890'."""
    return f"{rng.randint(1000, 9999)} {rng.randint(100000, 999999)}"


def full_name(rng: random.Random) -> str:
    return f"{rng.choice(_LAST_NAMES)} {rng.choice(_FIRST_NAMES)}"


# ---------- Описание тестовой таблицы ----------------------------------------

@dataclass(frozen=True)
class TestTableSpec:
    """Описание таблицы с ПДн для профилирования."""
    name: str
    rows: int = 100
    seed: int = 42

    @property
    def columns(self) -> list[tuple[str, str, Callable[[random.Random], str]]]:
        """(имя колонки, тип для разных СУБД, генератор значения)."""
        return [
            ("id",          "INT_PK",      lambda _: ""),   # PK ставится DDL'ом
            ("full_name",   "VARCHAR(100)", full_name),
            ("inn",         "VARCHAR(12)",  inn_12),
            ("phone",       "VARCHAR(16)",  phone_ru),
            ("passport",    "VARCHAR(12)",  passport_ru),
        ]


# ---------- DDL под три СУБД -------------------------------------------------

def _ddl_for(driver: str, spec: TestTableSpec) -> str:
    if driver == "oracle":
        cols = [
            "id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY",
            "full_name VARCHAR2(100)",
            "inn       VARCHAR2(12)",
            "phone     VARCHAR2(16)",
            "passport  VARCHAR2(12)",
        ]
        return f"CREATE TABLE {spec.name} ({', '.join(cols)})"
    if driver == "postgres":
        cols = [
            "id SERIAL PRIMARY KEY",
            "full_name VARCHAR(100)",
            "inn       VARCHAR(12)",
            "phone     VARCHAR(16)",
            "passport  VARCHAR(12)",
        ]
        return f"CREATE TABLE {spec.name} ({', '.join(cols)})"
    if driver == "mssql":
        cols = [
            "id INT IDENTITY(1,1) PRIMARY KEY",
            "full_name VARCHAR(100)",
            "inn       VARCHAR(12)",
            "phone     VARCHAR(16)",
            "passport  VARCHAR(12)",
        ]
        return f"CREATE TABLE {spec.name} ({', '.join(cols)})"
    raise NotImplementedError(driver)


def _insert_sql(driver: str, table: str) -> str:
    if driver == "oracle":
        return f"INSERT INTO {table} (full_name, inn, phone, passport) VALUES (:1, :2, :3, :4)"
    # psycopg и pymssql используют %s
    return f"INSERT INTO {table} (full_name, inn, phone, passport) VALUES (%s, %s, %s, %s)"


# ---------- Публичный API ----------------------------------------------------

def create_and_populate(client: DBClient, spec: TestTableSpec) -> None:
    """Создаёт таблицу и вставляет spec.rows строк с синтетическими ПДн."""
    log.info("Создаю тестовую таблицу %s (%d строк, seed=%d)",
             spec.name, spec.rows, spec.seed)
    client.execute(_ddl_for(client.driver_name, spec))

    rng = random.Random(spec.seed)
    sql = _insert_sql(client.driver_name, spec.name)
    for _ in range(spec.rows):
        client.execute(sql, (
            full_name(rng),
            inn_12(rng),
            phone_ru(rng),
            passport_ru(rng),
        ))


def drop_if_exists(client: DBClient, table: str) -> None:
    """Безопасный DROP — не падает, если таблицы нет."""
    drv = client.driver_name
    try:
        if drv == "oracle":
            client.execute(f"DROP TABLE {table} PURGE")
        elif drv == "postgres":
            client.execute(f"DROP TABLE IF EXISTS {table}")
        elif drv == "mssql":
            client.execute(
                f"IF OBJECT_ID('{table}', 'U') IS NOT NULL DROP TABLE {table}"
            )
    except Exception as e:  # noqa: BLE001 — drop должен быть максимально толерантным
        log.warning("drop_if_exists(%s) не удался: %s", table, e)
