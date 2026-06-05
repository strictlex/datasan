"""
SM-07: Запуск деперсонализации (стандартный).
Вызываем PFLB_PROCESS_DATA_TYPE и проверяем успешное завершение по логам.
"""
import os
import pytest
import time

@pytest.mark.smoke
def test_sm_07_depersonalization(db_client, test_logger):
    test_logger.info("SM-07: запуск деперсонализации")

    # Безопасное создание тестовой таблицы (без ORA-00942)
    db_client.execute("""
        BEGIN
            FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'SM07_TEST') LOOP
                EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name;
            END LOOP;
        END;
    """)
    db_client.execute("""
        BEGIN
            EXECUTE IMMEDIATE 'CREATE TABLE sm07_test (id NUMBER, full_name VARCHAR2(200))';
            FOR i IN 1..100 LOOP
                INSERT INTO sm07_test VALUES (i, 'Клиент ' || i);
            END LOOP;
            COMMIT;
        END;
    """)

    # Добавляем правило в PFLB_VIEWCONTENT (если нет)
    db_client.execute("""
        BEGIN
            DELETE FROM PFLB_VIEWCONTENT WHERE TABLE_NAME = 'SM07_TEST';
            INSERT INTO PFLB_VIEWCONTENT (TABLE_NAME, COLUMN_NAME, ENCODE_METHOD, COLUMN_ENCODE_TYPE)
            VALUES ('SM07_TEST', 'FULL_NAME', 'FIO', 'REPLACE');
            COMMIT;
        END;
    """)

    license_key = os.getenv('DATASAN_LICENSE_VALID', 'DUMMY_KEY')
    try:
        db_client.execute(f"""
            BEGIN
                PFLB_PROCESS_DATA_TYPE(
                    p_num_streams => 1,
                    p_commit_freq => 100,
                    p_license_key => '{license_key}'
                );
            END;
        """)
    except Exception as e:
        pytest.fail(f"Деперсонализация упала с ошибкой: {e}")

    # Проверяем логи на наличие завершающего сообщения
    time.sleep(2)
    result = db_client.execute("""
        SELECT COUNT(*) FROM PFLB_LOGS
        WHERE message LIKE '%exit from generate_update%'
    """)
    assert result and result[0][0] > 0, "Не найдено сообщение об успешном завершении в PFLB_LOGS"

    test_logger.info("SM-07: деперсонализация выполнена успешно")