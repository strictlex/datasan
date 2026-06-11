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


# ========== Генераторы для всех типов ПДн (корректные и некорректные) ==========

def snils_correct(rng: random.Random) -> str: # type: ignore
    """Генерирует валидный СНИЛС (11 цифр, контрольная сумма верна)."""
    # Генерируем первые 9 цифр
    digits = [rng.randint(0, 9) for _ in range(9)]
    # Вычисляем контрольное число
    total = sum(d * (9 - i) for i, d in enumerate(digits))
    checksum = total % 101
    if checksum == 100:
        checksum = 0
    # Добиваем до двух цифр
    checksum_str = f"{checksum:02d}"
    return "".join(map(str, digits)) + checksum_str


def snils_incorrect(rng: random.Random) -> str: # type: ignore
    """Генерирует неверный СНИЛС (правильная длина, но неправильная контрольная сумма)."""
    correct = snils_correct(rng)
    # Меняем одну из последних двух цифр
    if rng.choice([True, False]):
        # меняем предпоследнюю
        lst = list(correct)
        lst[-2] = str((int(lst[-2]) + 1) % 10)
        return "".join(lst)
    else:
        return correct[:-2] + "00"  # гарантированно неверная сумма


def ogrn_correct(rng: random.Random) -> str: # type: ignore
    """Генерирует валидный ОГРН (13 цифр для юрлица, 15 для ИП) – для простоты 13 цифр."""
    # Первые 12 цифр произвольные
    prefix = [rng.randint(0, 9) for _ in range(12)]
    # Вычисляем контрольную цифру
    ogrn_num = int("".join(map(str, prefix)))
    control = (ogrn_num % 11) % 10
    return "".join(map(str, prefix)) + str(control)


def ogrn_incorrect(rng: random.Random) -> str: # type: ignore
    """Неверный ОГРН (неправильная контрольная цифра)."""
    correct = ogrn_correct(rng)
    # Меняем последнюю цифру
    return correct[:-1] + str((int(correct[-1]) + 1) % 10)


def ip_correct(rng: random.Random) -> str: # type: ignore
    """Случайный IP-адрес (0-255 в каждом октете)."""
    return ".".join(str(rng.randint(0, 255)) for _ in range(4))


def ip_incorrect(rng: random.Random) -> str: # type: ignore
    """Неверный IP: либо 3 октета, либо буква, либо число >255."""
    variants = [
        ".".join(str(rng.randint(0, 255)) for _ in range(3)),  # три октета
        ".".join(str(rng.randint(0, 300)) for _ in range(4)),  # число >255
        f"192.168.{rng.randint(0,255)}.abc",                   # буква
    ]
    return rng.choice(variants)


def date_correct(rng: random.Random) -> str: # type: ignore
    """Случайная дата в формате YYYY-MM-DD (диапазон 1900-2100)."""
    year = rng.randint(1900, 2100)
    month = rng.randint(1, 12)
    day = rng.randint(1, 28)  # упрощённо, чтобы не заморачиваться с концом месяца
    return f"{year:04d}-{month:02d}-{day:02d}"


def date_incorrect(rng: random.Random) -> str: # type: ignore
    """Неверная дата: несуществующая дата или неверный формат."""
    variants = [
        "2025-02-30",       # несуществующий день
        "2025-13-01",       # месяц >12
        "not-a-date",
        "01-01-2025",       # другой порядок
    ]
    return rng.choice(variants)


def text_cyrillic(rng: random.Random) -> str: # type: ignore
    """Случайный кириллический текст (слова из списка имён и фамилий)."""
    name = rng.choice(_FIRST_NAMES + _LAST_NAMES)
    # иногда добавляем пробелы и цифры
    if rng.random() < 0.3:
        name += " " + str(rng.randint(1, 999))
    return name


def text_latin(rng: random.Random) -> str: # type: ignore
    """Латиница: случайная строка из букв."""
    length = rng.randint(3, 20)
    letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return "".join(rng.choice(letters) for _ in range(length))


# Словарь генераторов: ключ -> (gen_correct, gen_incorrect)
GENERATORS = {
    "inn_12": (inn_12, lambda rng: inn_12(rng) + "0"),  # просто добавим лишнюю цифру
    "snils": (snils_correct, snils_incorrect),
    "phone": (phone_ru, lambda rng: phone_ru(rng)[:-1]),   # удаляем последнюю цифру
    "passport": (passport_ru, lambda rng: passport_ru(rng).replace(" ", "")),  # без пробела
    "ip": (ip_correct, ip_incorrect),
    "ogrn": (ogrn_correct, ogrn_incorrect),
    "cardnumber": (lambda rng: "".join(str(rng.randint(0,9)) for _ in range(16)),
                   lambda rng: "".join(str(rng.randint(0,9)) for _ in range(15))),  # 15 цифр
    "date": (date_correct, date_incorrect),
    "text_cyrillic": (text_cyrillic, lambda rng: text_cyrillic(rng)[:5] + "!!!"),
    "text_latin": (text_latin, lambda rng: text_latin(rng) + "XYZ"),
    "full_name": (full_name, lambda rng: full_name(rng).replace(" ", "")),  # без пробела
}# ========== Генераторы для всех типов ПДн (корректные и некорректные) ==========

def snils_correct(rng: random.Random) -> str:
    """Генерирует валидный СНИЛС (11 цифр, контрольная сумма верна)."""
    # Генерируем первые 9 цифр
    digits = [rng.randint(0, 9) for _ in range(9)]
    # Вычисляем контрольное число
    total = sum(d * (9 - i) for i, d in enumerate(digits))
    checksum = total % 101
    if checksum == 100:
        checksum = 0
    # Добиваем до двух цифр
    checksum_str = f"{checksum:02d}"
    return "".join(map(str, digits)) + checksum_str


def snils_incorrect(rng: random.Random) -> str:
    """Генерирует неверный СНИЛС (правильная длина, но неправильная контрольная сумма)."""
    correct = snils_correct(rng)
    # Меняем одну из последних двух цифр
    if rng.choice([True, False]):
        # меняем предпоследнюю
        lst = list(correct)
        lst[-2] = str((int(lst[-2]) + 1) % 10)
        return "".join(lst)
    else:
        return correct[:-2] + "00"  # гарантированно неверная сумма


def ogrn_correct(rng: random.Random) -> str:
    """Генерирует валидный ОГРН (13 цифр для юрлица, 15 для ИП) – для простоты 13 цифр."""
    # Первые 12 цифр произвольные
    prefix = [rng.randint(0, 9) for _ in range(12)]
    # Вычисляем контрольную цифру
    ogrn_num = int("".join(map(str, prefix)))
    control = (ogrn_num % 11) % 10
    return "".join(map(str, prefix)) + str(control)


def ogrn_incorrect(rng: random.Random) -> str:
    """Неверный ОГРН (неправильная контрольная цифра)."""
    correct = ogrn_correct(rng)
    # Меняем последнюю цифру
    return correct[:-1] + str((int(correct[-1]) + 1) % 10)


def ip_correct(rng: random.Random) -> str:
    """Случайный IP-адрес (0-255 в каждом октете)."""
    return ".".join(str(rng.randint(0, 255)) for _ in range(4))


def ip_incorrect(rng: random.Random) -> str:
    """Неверный IP: либо 3 октета, либо буква, либо число >255."""
    variants = [
        ".".join(str(rng.randint(0, 255)) for _ in range(3)),  # три октета
        ".".join(str(rng.randint(0, 300)) for _ in range(4)),  # число >255
        f"192.168.{rng.randint(0,255)}.abc",                   # буква
    ]
    return rng.choice(variants)


def date_correct(rng: random.Random) -> str:
    """Случайная дата в формате YYYY-MM-DD (диапазон 1900-2100)."""
    year = rng.randint(1900, 2100)
    month = rng.randint(1, 12)
    day = rng.randint(1, 28)  # упрощённо, чтобы не заморачиваться с концом месяца
    return f"{year:04d}-{month:02d}-{day:02d}"


def date_incorrect(rng: random.Random) -> str:
    """Неверная дата: несуществующая дата или неверный формат."""
    variants = [
        "2025-02-30",       # несуществующий день
        "2025-13-01",       # месяц >12
        "not-a-date",
        "01-01-2025",       # другой порядок
    ]
    return rng.choice(variants)


def text_cyrillic(rng: random.Random) -> str:
    """Случайный кириллический текст (слова из списка имён и фамилий)."""
    name = rng.choice(_FIRST_NAMES + _LAST_NAMES)
    # иногда добавляем пробелы и цифры
    if rng.random() < 0.3:
        name += " " + str(rng.randint(1, 999))
    return name


def text_latin(rng: random.Random) -> str:
    """Латиница: случайная строка из букв."""
    length = rng.randint(3, 20)
    letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return "".join(rng.choice(letters) for _ in range(length))


# Словарь генераторов: ключ -> (gen_correct, gen_incorrect)
GENERATORS = {
    "inn_12": (inn_12, lambda rng: inn_12(rng) + "0"),  # просто добавим лишнюю цифру
    "snils": (snils_correct, snils_incorrect),
    "phone": (phone_ru, lambda rng: phone_ru(rng)[:-1]),   # удаляем последнюю цифру
    "passport": (passport_ru, lambda rng: passport_ru(rng).replace(" ", "")),  # без пробела
    "ip": (ip_correct, ip_incorrect),
    "ogrn": (ogrn_correct, ogrn_incorrect),
    "cardnumber": (lambda rng: "".join(str(rng.randint(0,9)) for _ in range(16)),
                   lambda rng: "".join(str(rng.randint(0,9)) for _ in range(15))),  # 15 цифр
    "date": (date_correct, date_incorrect),
    "text_cyrillic": (text_cyrillic, lambda rng: text_cyrillic(rng)[:5] + "!!!"),
    "text_latin": (text_latin, lambda rng: text_latin(rng) + "XYZ"),
    "full_name": (full_name, lambda rng: full_name(rng).replace(" ", "")),  # без пробела
}