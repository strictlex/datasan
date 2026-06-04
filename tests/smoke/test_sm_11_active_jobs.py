"""
SM-11: Активные задания.
Во время выполнения деперсонализации таблица PFLB_ACTIVE_JOBS должна содержать записи.
"""
import pytest
import threading
import time
import os

def run_depersonalization(db_client, error_holder, license_key):
    try:
        db_client.execute(f"""
            BEGIN
                PFLB_PROCESS_DATA_TYPE(1, 100, '{license_key}');
            END;
        """)
    except Exception as e:
        error_holder.append(e)

@pytest.mark.smoke
def test_sm_11_active_jobs(db_client, test_logger):
    test_logger.info("SM-11: проверка активных заданий во время деперсонализации")

    # Подготовка тестовой таблицы (достаточно большой, чтобы процедура работала не мгновенно)
    db_client.execute("""
        BEGIN
            BEGIN EXECUTE IMMEDIATE 'DROP TABLE sm11_test'; EXCEPTION WHEN OTHERS THEN NULL; END;
            EXECUTE IMMEDIATE 'CREATE TABLE sm11_test (id NUMBER, data VARCHAR2(200))';
            FOR i IN 1..5000 LOOP
                INSERT INTO sm11_test VALUES (i, 'Sensitive data ' || i);
            END LOOP;
            COMMIT;
            DELETE FROM PFLB_VIEWCONTENT WHERE TABLE_NAME = 'SM11_TEST';
            INSERT INTO PFLB_VIEWCONTENT (TABLE_NAME, COLUMN_NAME, ENCODE_METHOD, COLUMN_ENCODE_TYPE)
            VALUES ('SM11_TEST', 'DATA', 'FULL_MASK', 'REPLACE');
            COMMIT;
        END;
    """)

    license_key = os.getenv('DATASAN_LICENSE_VALID', 'DUMMY_KEY')
    errors = []
    thread = threading.Thread(target=run_depersonalization, args=(db_client, errors, license_key))
    thread.start()

    # Даём процедуре время зарегистрироваться
    time.sleep(2)

    result = db_client.execute("SELECT COUNT(*) FROM PFLB_ACTIVE_JOBS")
    assert result and result[0][0] > 0, "PFLB_ACTIVE_JOBS пуста, хотя деперсонализация должна работать"

    thread.join(timeout=120)
    if errors:
        pytest.fail(f"Ошибка при выполнении деперсонализации: {errors[0]}")

    test_logger.info("SM-11: активные задания обнаружены")