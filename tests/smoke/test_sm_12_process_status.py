import os
import pytest

@pytest.mark.smoke
def test_sm_12_process_status(db_client, test_logger):
    test_logger.info("SM-12: проверка статуса после деперсонализации")

    license_key = os.getenv('DATASAN_LICENSE_VALID', '').strip()
    if not license_key:
        pytest.fail("DATASAN_LICENSE_VALID не задан")

    try:
        db_client.execute(f"""
            BEGIN
                PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                    '{license_key}', 'FULL_MASK', 1, 100, 0, 1, 1, 1
                );
            END;
        """)
    except Exception as e:
        pytest.fail(f"Деперсонализация не выполнена: {e}")

    result = db_client.execute("SELECT COUNT(*) FROM PFLB_ACTIVE_STATUS")
    count = result[0][0] if result else 0
    assert count == 0, f"PFLB_ACTIVE_STATUS не пуста ({count} записей)"

    test_logger.info("SM-12: успешно")