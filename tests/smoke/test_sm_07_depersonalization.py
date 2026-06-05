import os
import pytest
import time

@pytest.mark.smoke
def test_sm_07_depersonalization(db_client, test_logger):
    test_logger.info("SM-07: запуск деперсонализации")

    # 1. Удаляем таблицу, если существует
    db_client.execute("""
        BEGIN
            FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'SM07_TEST') LOOP
                EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name;
            END LOOP;
        END;
    """)

    # 2. Создаём таблицу отдельным вызовом
    try:
        db_client.execute("""
            CREATE TABLE sm07_test (
                id NUMBER,
                full_name VARCHAR2(200)
            )
        """)
    except Exception as e:
        pytest.fail(f"Не удалось создать таблицу sm07_test: {e}")

    # 3. Заполняем тестовыми данными
    db_client.execute("""
        BEGIN
            FOR i IN 1..100 LOOP
                INSERT INTO sm07_test VALUES (i, 'Клиент ' || i);
            END LOOP;
            COMMIT;
        END;
    """)

    # 4. Добавляем правило в PFLB_VIEWCONTENT
    db_client.execute("""
        BEGIN
            DELETE FROM PFLB_VIEWCONTENT WHERE TABLE_NAME = 'SM07_TEST';
            INSERT INTO PFLB_VIEWCONTENT (TABLE_NAME, COLUMN_NAME, ENCODE_METHOD, COLUMN_ENCODE_TYPE)
            VALUES ('SM07_TEST', 'FULL_NAME', 'FIO', 'REPLACE');
            COMMIT;
        END;
    """)

    # 5. Вызываем деперсонализацию (с полной сигнатурой)
    license_key = os.getenv('DATASAN_LICENSE_VALID', '').strip()
    if not license_key:
        pytest.fail("DATASAN_LICENSE_VALID не задан")

    try:
        db_client.execute(f"""
            BEGIN
                PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                    p_license_key => '{license_key}',
                    p_encode_method => 'FIO',
                    p_num_streams => 1,
                    p_rows_per_update => 100,
                    p_simulate => 0,
                    p_thread_per_dechannel => 1,
                    p_de_channel => 1,
                    p_as_channel => 1
                );
            END;
        """)
    except Exception as e:
        pytest.fail(f"Ошибка при вызове деперсонализации: {e}")

    # 6. Проверяем логи
    time.sleep(2)
    result = db_client.execute("""
        SELECT COUNT(*) FROM PFLB_LOGS
        WHERE message LIKE '%exit from generate_update%'
    """)
    assert result and result[0][0] > 0, "Сообщение об успешном завершении не найдено в PFLB_LOGS"

    test_logger.info("SM-07: успешно")