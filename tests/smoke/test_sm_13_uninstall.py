"""
SM-13: Удаление DataSan.

Запускает drop-скрипты и проверяет что ключевые объекты DataSan
(таблицы, процедуры, функции) удалены из схемы.
"""
from __future__ import annotations

import pytest

# Ключевые объекты DataSan — должны отсутствовать после удаления.
EXPECTED_ABSENT = [
    ("TABLE",     "PFLB_LOGS"),
    ("TABLE",     "PFLB_VIEWCONTENT"),
    ("TABLE",     "PFLB_ACTIVE_JOBS"),
    ("TABLE",     "PFLB_PROCESSED_TABLES"),
    ("TABLE",     "PFLB_RESULT_TYPES"),
    ("PACKAGE",   "PFLB_DATASAN"),
    ("FUNCTION",  "PFLB_ENCODE_HASH_CHAR"),
    ("FUNCTION",  "PFLB_ENCODE_HASH_INNUMBER"),
]


@pytest.mark.smoke
def test_sm_13_uninstall_datasan(sql_runner, sql_dir, db_client, test_logger):
    """SM-13: запускает drop-скрипты и проверяет отсутствие объектов DataSan."""
    drop_dir = sql_dir / "drop"

    assert drop_dir.exists(), f"Не найден каталог drop-скриптов: {drop_dir}"

    test_logger.info("SM-13: запускаю drop-скрипты из %s", drop_dir)
    applied = sql_runner.run_dir(drop_dir)
    test_logger.info("SM-13: применено statements: %d", applied)

    # Проверяем что ключевые объекты удалены
    missing_check_sql = """
        SELECT COUNT(*) FROM user_objects
        WHERE object_type = :obj_type
        AND object_name = :obj_name
    """

    still_present = []
    for obj_type, obj_name in EXPECTED_ABSENT:
        count = db_client.fetch_scalar(
            missing_check_sql,
            {"obj_type": obj_type, "obj_name": obj_name},
        )
        if count and int(count) > 0:
            still_present.append(f"{obj_type} {obj_name}")
        else:
            test_logger.info("SM-13: %s %s — удалён ✓", obj_type, obj_name)

    assert not still_present, (
        f"SM-13: следующие объекты DataSan не были удалены: {still_present}"
    )
