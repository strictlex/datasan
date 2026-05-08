"""
SM-10: Логирование (общий лог).

PFLB_LOGS имеет колонки: ID, LSTR (сообщение), LDATE, SID.
Процедура логирования: PFLB_DATASAN.PFLB_WRITE_LOGS(message).
"""
from __future__ import annotations

import pytest

_TEST_MESSAGE = "SM-10 autotest: logging check"


@pytest.mark.smoke
def test_sm_10_logging(db_client, test_logger):
    """SM-10: PFLB_LOGS доступна и PFLB_DATASAN.PFLB_WRITE_LOGS пишет записи."""

    # 1. Таблица существует
    count = db_client.fetch_scalar(
        "SELECT COUNT(*) FROM user_objects "
        "WHERE object_name = 'PFLB_LOGS' AND object_type = 'TABLE'"
    )
    assert count and int(count) > 0, "Таблица PFLB_LOGS не найдена в схеме"
    test_logger.info("SM-10: PFLB_LOGS существует ✓")

    # 2. Считаем записи до теста
    before = int(db_client.fetch_scalar("SELECT COUNT(*) FROM pflb_logs") or 0)
    test_logger.info("SM-10: записей в PFLB_LOGS до теста: %d", before)

    # 3. Пишем тестовую запись через процедуру DataSan
    db_client.execute(
        "BEGIN PFLB_DATASAN.PFLB_WRITE_LOGS(:msg); END;",
        {"msg": _TEST_MESSAGE},
    )
    test_logger.info("SM-10: вызвал PFLB_DATASAN.PFLB_WRITE_LOGS('%s')", _TEST_MESSAGE)

    # 4. Проверяем что запись появилась
    after = int(db_client.fetch_scalar("SELECT COUNT(*) FROM pflb_logs") or 0)
    test_logger.info("SM-10: записей в PFLB_LOGS после теста: %d", after)

    assert after > before, (
        f"PFLB_WRITE_LOGS не записала в PFLB_LOGS: до={before}, после={after}"
    )

    # 5. Проверяем что наше сообщение есть в таблице (колонка LSTR)
    found = db_client.fetch_scalar(
        "SELECT COUNT(*) FROM pflb_logs WHERE lstr LIKE :msg",
        {"msg": f"%{_TEST_MESSAGE}%"},
    )
    assert found and int(found) > 0, (
        f"Сообщение '{_TEST_MESSAGE}' не найдено в PFLB_LOGS.LSTR"
    )
    test_logger.info("SM-10: сообщение найдено в PFLB_LOGS ✓")
