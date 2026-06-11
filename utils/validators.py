"""
Валидаторы для проверки форматов данных после маскирования.
Каждый валидатор принимает строку (или None) и возвращает bool.
"""
from __future__ import annotations

import re


def valid_inn(value: str | None) -> bool:
    """10 или 12 цифр (контрольная сумма не проверяется)."""
    if not value:
        return False
    # Удаляем возможные пробелы
    cleaned = value.replace(' ', '')
    return cleaned.isdigit() and len(cleaned) in (10, 12)


def valid_phone(value: str | None) -> bool:
    if not value:
        return False
    # Удаляем всё, кроме цифр и плюса в начале
    cleaned = re.sub(r'[^\d+]', '', value)
    # Если начинается с +, убираем +
    if cleaned.startswith('+'):
        cleaned = cleaned[1:]
    return len(cleaned) == 11 and cleaned.isdigit() and cleaned[0] == '7'


def valid_ip(value: str | None) -> bool:
    """Четыре числа, разделённых точкой (числа могут быть любыми)."""
    if not value:
        return False
    parts = value.split('.')
    if len(parts) != 4:
        return False
    # Проверяем, что каждый октет состоит только из цифр
    for part in parts:
        if not part.isdigit():
            return False
    return True


def valid_passport(value: str | None) -> bool:
    """Формат: 4 цифры пробел 6 цифр (пробел может отсутствовать)."""
    if not value:
        return False
    # Удаляем пробел для проверки
    cleaned = value.replace(' ', '')
    return len(cleaned) == 10 and cleaned.isdigit()


def valid_snils(value: str | None) -> bool:
    """11 цифр."""
    if not value:
        return False
    cleaned = value.replace(' ', '')
    return len(cleaned) == 11 and cleaned.isdigit()


def valid_ogrn(value: str | None) -> bool:
    """13 или 15 цифр."""
    if not value:
        return False
    cleaned = value.replace(' ', '')
    return cleaned.isdigit() and len(cleaned) in (13, 15)


def valid_cardnumber(value: str | None) -> bool:
    """16 цифр (с пробелами или без)."""
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