import os
import pytest
import threading
import time

def run_depersonalization(db_client, error_holder, license_key):
    try:
        db_client.execute(f"""
            BEGIN
                PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                    '{license_key}', 'FULL_MASK', 1, 100, 0, 1, 1, 1
                );
            END;
        """)
    except Exception as e:
        error_holder.append(e)

@pytest.mark.smoke
def test_sm_11_active_jobs(db_client, test_logger):
    test_logger.info("SM-11: проверка активных заданий")

    # Подготовка таблицы
    db_client.execute("""
        BEGIN
            FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'SM11_TEST') LOOP
                EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name;
            END LOOP;
        END;
    """)
    try:
        db_client.execute("""
            CREATE TABLE sm11_test (
                id NUMBER,
                data VARCHAR2(200)
            )
        """)
    except Exception as e:
        pytest.fail(f"Не удалось создать таблицу sm11_test: {e}")

    db_client.execute("""
        BEGIN
            FOR i IN 1..5000 LOOP
                INSERT INTO sm11_test VALUES (i, 'Sensitive data ' || i);
            END LOOP;
            COMMIT;
        END;
    """)

    db_client.execute("""
        BEGIN
            DELETE FROM PFLB_VIEWCONTENT WHERE TABLE_NAME = 'SM11_TEST';
            INSERT INTO PFLB_VIEWCONTENT (TABLE_NAME, COLUMN_NAME, ENCODE_METHOD, COLUMN_ENCODE_TYPE)
            VALUES ('SM11_TEST', 'DATA', 'FULL_MASK', 'REPLACE');
            COMMIT;
        END;
    """)

    license_key = os.getenv('DATASAN_LICENSE_VALID', '').strip()
    if not license_key:
        pytest.fail("DATASAN_LICENSE_VALID не задан")


    # Внутри test_sm_11_active_jobs

errors = []
thread = threading.Thread(target=run_depersonalization, args=(db_client, errors, license_key))
thread.start()

# Даём процедуре время зарегистрироваться – больше ожидание
time.sleep(5)

# Проверяем, что появилась активная запись (с повторными попытками)
active_jobs_found = False
for attempt in range(10):
    result = db_client.execute("SELECT COUNT(*) FROM PFLB_ACTIVE_JOBS")
    if result and result[0][0] > 0:
        active_jobs_found = True
        break
    time.sleep(1)

assert active_jobs_found, "PFLB_ACTIVE_JOBS осталась пуста через 15 секунд"

# Дожидаемся завершения потока
thread.join(timeout=300)
if errors:
    pytest.fail(f"Ошибка при выполнении деперсонализации: {errors[0]}")


    
    # errors = []
    # thread = threading.Thread(target=run_depersonalization, args=(db_client, errors, license_key))
    # thread.start()
    # time.sleep(5)

    # # Проверяем, что появилась активная запись
    # result = db_client.execute("SELECT COUNT(*) FROM PFLB_ACTIVE_JOBS")
    # assert result and result[0][0] > 0, "PFLB_ACTIVE_JOBS пуста"

    # thread.join(timeout=120)
    # if errors:
    #     pytest.fail(f"Ошибка при деперсонализации: {errors[0]}")

    # test_logger.info("SM-11: успешно")