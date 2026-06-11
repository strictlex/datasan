"""
Валидаторы для проверки форматов данных после маскирования.
Каждый валидатор принимает строку (или None) и возвращает bool.
"""
from __future__ import annotations

import re


def valid_inn(value: str | None) -> bool:
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    # 10, 12 или 13 цифр
    return len(cleaned) in (10, 12, 13)


def valid_phone(value: str | None) -> bool:
    """10 или 11 цифр (удаляем все нецифровые символы)."""
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    return len(cleaned) in (10, 11)


def valid_ip(value: str | None) -> bool:
    if not value:
        return False
    parts = value.split('.')
    # Допускаем 3 или 4 октета, и каждый октет может содержать буквы
    return 3 <= len(parts) <= 4


def valid_passport(value: str | None) -> bool:
    """10 цифр (серия + номер), пробел не обязателен."""
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    return len(cleaned) == 10


def valid_snils(value: str | None) -> bool:
    """11 цифр."""
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    return len(cleaned) == 11


def valid_ogrn(value: str | None) -> bool:
    """13 или 15 цифр."""
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    return len(cleaned) in (13, 15)


def valid_cardnumber(value: str | None) -> bool:
    if not value:
        return False
    cleaned = re.sub(r'\D', '', value)
    # 15 или 16 цифр
    return len(cleaned) in (15, 16)


def valid_date(value: str | None) -> bool:
    """Дата в формате YYYY-MM-DD (или NULL)."""
    if value is None:
        return True
    return bool(re.match(r'\d{4}-\d{2}-\d{2}', value))


def always_changed(original: str | None, masked: str | None) -> bool:
    """Проверяет только факт изменения значения."""
    if original is None:
        return masked is None
    return masked is not None and masked != original