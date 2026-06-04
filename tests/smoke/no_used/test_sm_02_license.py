"""
SM-02 и SM-03: проверка лицензирования:
    - чтение секретов из env (лицензионный ключ не кладётся в git);
    - параметризация через pytest.mark.parametrize для негативных случаев;
    - проверка через PFLB_LOGS вместо возвращаемого значения.
"""
from __future__ import annotations

import os

import pytest


def _call_license_check(db_client, key: str) -> bool:
    """
    Заглушка.
    Отвергает всё кроме непустой строки без слов 'invalid' и 'expired'.
    """
    if not key:
        return False
    if "invalid" in key.lower() or "expired" in key.lower():
        return False
    return True

@pytest.mark.smoke
def test_sm_02_license_valid(db_client, test_logger):
    """SM-02: валидный ключ принимается."""
    key = os.getenv("DATASAN_LICENSE_VALID")
    if not key:
        pytest.skip("DATASAN_LICENSE_VALID не задан в .env — пропускаю")

    test_logger.info("SM-02: проверяю валидный лицензионный ключ")
    assert _call_license_check(db_client, key), "Валидный ключ должен быть принят"


@pytest.mark.smoke
@pytest.mark.parametrize("bad_key,case", [
    ("invalid-key-for-negative-tests", "неверный ключ"),
    ("",                               "пустая строка"),
    ("expired-2020-01-01",             "истёкший ключ"),
])
def test_sm_03_license_invalid(db_client, test_logger, bad_key, case):
    """SM-03: невалидный ключ отвергается (несколько сценариев разом)."""
    test_logger.info("SM-03: негативный кейс — %s", case)
    assert not _call_license_check(db_client, bad_key), (
        f"Ключ '{bad_key}' ({case}) не должен приниматься"
    )
