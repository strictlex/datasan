"""
SM-01: Установка DataSan.

Перед установкой автоматически запускает drop-скрипты (idempotent),
чтобы тест был повторяемым.
"""
from __future__ import annotations
import pytest


@pytest.mark.smoke
def test_sm_01_install_datasan(sql_runner, sql_dir, test_logger):
    install_dir = sql_dir / "install"
    drop_dir = sql_dir / "drop"

    # Cleanup перед установкой — делаем idempotent
    if drop_dir.exists():
        test_logger.info("SM-01: предварительный drop из %s", drop_dir)
        try:
            sql_runner.run_dir(drop_dir)
        except Exception as e:
            test_logger.warning("SM-01: drop завершился с предупреждением: %s", e)

    assert install_dir.exists(), \
        f"Не найден каталог установочных скриптов: {install_dir}"

    test_logger.info("SM-01: запускаю установочные скрипты из %s", install_dir)
    applied = sql_runner.run_dir(install_dir)
    test_logger.info("SM-01: применено statement'ов: %d", applied)

    assert applied > 0, (
        f"В {install_dir} не найдено ни одного .sql-файла."
    )
