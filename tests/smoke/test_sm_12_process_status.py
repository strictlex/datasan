"""
SM-12: Статус процесса после завершения.
Таблица PFLB_ACTIVE_STATUS должна быть пуста (нет ошибок/незавершённых процессов).
"""
import pytest
import os

@pytest.mark.smoke
def test_sm_12_process_status(db_client, test_logger):
    test_logger.info("SM-12: проверка статуса после деперсонализации")

    license_key = os.getenv('DATASAN_LICENSE_VALID', 'DUMMY_KEY')
    # Выполняем деперсонализацию (можно синхронно)
    db_client.execute(f"""
        BEGIN
            PFLB_PROCESS_DATA_TYPE(1, 100, '{license_key}');
        END;
    """)

    result = db_client.execute("SELECT COUNT(*) FROM PFLB_ACTIVE_STATUS")
    count = result[0][0] if result else 0
    assert count == 0, f"PFLB_ACTIVE_STATUS не пуста, найдено {count} записей"

    test_logger.info("SM-12: статус процесса корректен")