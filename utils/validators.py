"""
Валидаторы для проверки форматов данных после маскирования.
Каждый валидатор принимает строку (или None) и возвращает bool.
"""
from __future__ import annotations

import re


def valid_inn(value: str | None) -> bool:
    """12 цифр (контрольная сумма не проверяется, DataSan её не сохраняет)."""
    if not value:
        return False
    return len(value) == 12 and value.isdigit()


def valid_phone(value: str | None) -> bool:
    """Начинается с 7 или +7, итого 11 или 12 символов, только цифры после +."""
    if not value:
        return False
    digits = value.lstrip('+')
    return digits.startswith('7') and len(digits) == 11 and digits.isdigit()


def valid_ip(value: str | None) -> bool:
    """Четыре числовых октета разделённых точкой (0-255 не проверяем)."""
    if not value:
        return False
    parts = value.split('.')
    return len(parts) == 4 and all(p.isdigit() for p in parts)


def valid_passport(value: str | None) -> bool:
    """Формат: 4 цифры пробел 6 цифр."""
    return bool(value and re.fullmatch(r'\d{4} \d{6}', value))


def valid_snils(value: str | None) -> bool:
    """11 цифр."""
    return bool(value and len(value) == 11 and value.isdigit())


def valid_ogrn(value: str | None) -> bool:
    """13 или 15 цифр."""
    return bool(value and (len(value) == 13 or len(value) == 15) and value.isdigit())


def valid_cardnumber(value: str | None) -> bool:
    """16 цифр, возможны пробелы – упрощённо: удаляем пробелы и проверяем длину."""
    if not value:
        return False
    cleaned = value.replace(' ', '')
    return len(cleaned) == 16 and cleaned.isdigit()


def valid_date(value: str | None) -> bool:
    """Проверяет, что строка может быть датой в формате YYYY-MM-DD (или NULL)."""
    if value is None:
        return True
    # Oracle может вернуть date в виде строки, но для теста достаточно проверки формата
    return bool(re.match(r'\d{4}-\d{2}-\d{2}', value))


def always_changed(original: str | None, masked: str | None) -> bool:
    """Проверяет только факт изменения значения (не равно и не NULL, если original не NULL)."""
    if original is None:
        return masked is None
    return masked is not None and masked != original