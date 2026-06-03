import pytest
import threading
import time

@pytest.mark.smoke
def test_sm_11_active_jobs(db_client, test_logger):
    """
    SM-11: проверка, что во время деперсонализации создаются джобы.
    """
    test_logger.info("SM-11: подготовка таблицы с большим количеством строк")
    
    # db_client.execute("BEGIN DROP TABLE test_sm11 PURGE END;")
    try:
        db_client.execute("DROP TABLE test_sm11 PURGE")
    except Exception as e:
        # Таблицы нет — игнорируем
        test_logger.info("Таблица test_sm11 не существовала, пропускаем DROP")
    db_client.execute("""
        CREATE TABLE test_sm11 (
            id NUMBER PRIMARY KEY,
            payload VARCHAR2(100)
        )
    """)
    # Вставляем 2000 строк, чтобы процесс шёл не мгновенно
    for i in range(1, 2001):
        db_client.execute(f"INSERT INTO test_sm11 VALUES ({i}, 'data_{i}')")
    # db_client.commit()
    
    # Регистрируем в профиле
    db_client.execute("DELETE FROM PFLB_VIEWCONTENT WHERE table_name = 'TEST_SM11'")
    db_client.execute("""
        INSERT INTO PFLB_VIEWCONTENT (owner_name, table_name, column_name, encode_method, column_encode_type)
        VALUES ('SMOKE_TEST', 'TEST_SM11', 'PAYLOAD', 'CHAR', 'CHAR')
    """)
    # db_client.commit()
    
    # Функция, которая запускает деперсонализацию
    def run_masking():
        try:
            db_client.execute("""
                BEGIN
                    PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                        '70FCD8-DA7721-A47226-9C2ED7',
                        'CHAR',
                        2,          -- потоки
                        100,        -- маленький chunk, чтобы дольше работало
                        0,
                        1,
                        1,
                        1
                    );
                END;
            """)
            # db_client.commit()
        except Exception as e:
            test_logger.error(f"Ошибка в потоке: {e}")
    
    test_logger.info("SM-11: запуск деперсонализации в фоне")
    thread = threading.Thread(target=run_masking)
    thread.start()
    
    # Даём время на создание джобов
    time.sleep(3)
    
    # Проверяем, что PFLB_ACTIVE_JOBS не пуста
    count = db_client.fetch_scalar("SELECT COUNT(*) FROM PFLB_ACTIVE_JOBS")
    test_logger.info(f"Активных джобов: {count}")
    assert count > 0, "Не создано ни одного джоба"
    
    # Ждём завершения (максимум 60 секунд)
    thread.join(timeout=60)
    
    # После завершения джобы должны быть удалены
    count_after = db_client.fetch_scalar("SELECT COUNT(*) FROM PFLB_ACTIVE_JOBS")
    test_logger.info(f"Джобов после завершения: {count_after}")
    assert count_after == 0, "После деперсонализации остались записи в ACTIVE_JOBS"
    
    # Очистка
    db_client.execute("DROP TABLE test_sm11 PURGE")
    # db_client.commit()
    test_logger.info("SM-11: пройден")