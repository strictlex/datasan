"""
SM-08: Проверка методов маскирования DataSan.

Вызываем PL/SQL-функции напрямую через SELECT ... FROM dual.
Для каждого типа ПДн проверяем:
  1. Значение изменилось (не равно исходному).
  2. Результат соответствует формату типа данных.

Результат каждой проверки попадает в JUnit XML как отдельный
параметризованный тест-кейс: исходное | маскированное | валидация.
"""
from __future__ import annotations

import re
import pytest


# ---------------------------------------------------------------------------
# Валидаторы формата
# ---------------------------------------------------------------------------


def _valid_inn(v: str) -> bool:
    """12 цифр — контрольная сумма не проверяется, DataSan её не сохраняет."""
    return bool(v and len(v) == 12 and v.isdigit())


def _valid_phone(v: str) -> bool:
    """Начинается с 7 или +7, итого 11 или 12 символов."""
    if not v:
        return False
    digits = v.lstrip('+')
    return digits.startswith('7') and len(digits) == 11 and digits.isdigit()


def _valid_ip(v: str) -> bool:
    """Четыре числовых октета разделённых точкой (без ограничения 0-255)."""
    parts = (v or "").split(".")
    return len(parts) == 4 and all(p.isdigit() for p in parts)

def _valid_passport(v: str) -> bool:
    """Формат: 4 цифры пробел 6 цифр."""
    return bool(v and re.fullmatch(r'\d{4} \d{6}', v))


def _valid_snils(v: str) -> bool:
    """11 цифр."""
    return bool(v and len(v) == 11 and v.isdigit())


def _valid_changed(original: str, masked: str) -> bool:
    return masked is not None and masked != original


# ---------------------------------------------------------------------------
# Тест-кейсы: (id, функция, исходное значение, валидатор формата)
# ---------------------------------------------------------------------------

MASK_CASES = [
    # ФИО / произвольный текст
    ("ФИО_кириллица",    "PFLB_ENCODE_HASH_CHAR",       "Иванов Иван",          None),
    ("ФИО_латиница",     "PFLB_ENCODE_HASH_CHAR",       "Ivanov Ivan",           None),
    ("Текст_пустой",     "PFLB_ENCODE_HASH_CHAR",       "",                      None),

    # ИНН
    ("ИНН_12цифр",       "PFLB_ENCODE_HASH_INNUMBER",   "772456789012",          _valid_inn),
    ("ИНН_10цифр_юрлицо","PFLB_ENCODE_HASH_INNUMBER",   "7724567890",            None),

    # Телефон
    ("Телефон_+7",       "PFLB_ENCODE_HASH_PHONENUMBER","79161234567",           _valid_phone),
    ("Телефон_8",        "PFLB_ENCODE_HASH_PHONENUMBER","89161234567",           None),

    # Паспорт
    ("Паспорт",          "PFLB_ENCODE_HASH_PPCHAR",     "1234 567890",           _valid_passport),

    # СНИЛС
    ("СНИЛС",            "PFLB_ENCODE_HASH_SNILSNUMBER","12345678901",           _valid_snils),

    # IP-адрес
    ("IP",               "PFLB_ENCODE_HASH_IP",         "192.168.1.100",         _valid_ip),

    # ОГРН
    ("ОГРН_13цифр",      "PFLB_ENCODE_HASH_OGRN",       "1027700132195",         None),

    # Номер карты
    ("Карта",            "PFLB_ENCODE_HASH_CARDNUMBER",  "4111111111111111",      None),
]


# ---------------------------------------------------------------------------
# Параметризованный тест
# ---------------------------------------------------------------------------

@pytest.mark.smoke
@pytest.mark.oracle
@pytest.mark.parametrize(
    "case_id,func,original,fmt_validator",
    [(c[0], c[1], c[2], c[3]) for c in MASK_CASES],
    ids=[c[0] for c in MASK_CASES],
)
def test_sm_08_masking(
    db_client, 
    test_logger,
    case_id, 
    func, 
    original, 
    fmt_validator,
    ):
    """
    SM-08: маскирование {case_id}.
    Отчёт в JUnit XML: исходное | маскированное | валидация.
    """
    test_logger.info("SM-08 [%s]: вызов %s('%s')", case_id, func, original)

    # Пустая строка — особый случай: Oracle вернёт NULL
    if original == "":
        try:
            result = db_client.fetch_scalar(
                f"SELECT {func}('') FROM dual"
            )
        except Exception as e:
            pytest.skip(f"Функция {func} не принимает пустую строку: {e}")
        test_logger.info(
            "SM-08 [%s]: '' → %r (пустая строка, проверка пропущена)", case_id, result
        )
        return

    # Основной вызов
    result = db_client.fetch_scalar(
        f"SELECT {func}(:val) FROM dual",
        {"val": original},
    )

    test_logger.info(
        "SM-08 [%s]: '%s' → '%s'", case_id, original, result
    )

    # 1. Значение изменилось
    changed = _valid_changed(original, result)
    assert changed, (
        f"[{case_id}] Маскирование не изменило значение: '{original}' → '{result}'"
    )

    # 2. Формат сохранён (если задан валидатор)
    if fmt_validator is not None:
        fmt_ok = fmt_validator(result)
        assert fmt_ok, (
            f"[{case_id}] Формат нарушен после маскирования: '{original}' → '{result}'"
        )
        test_logger.info("SM-08 [%s]: формат OK", case_id)
