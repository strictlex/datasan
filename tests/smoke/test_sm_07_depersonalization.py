import pytest

@pytest.mark.smoke
def test_sm_07_depersonalization(db_client, test_logger):
    """
    SM-07: запуск стандартной деперсонализации через PFLB_PROCESS_DATA_TYPE.
    """
    test_logger.info("SM-07: подготовка тестовой таблицы")
    
    # 1. Создаём таблицу с тестовыми данными
    db_client.execute("DROP TABLE test_sm07 PURGE")
    db_client.execute("""
        CREATE TABLE test_sm07 (
            id NUMBER PRIMARY KEY,
            inn VARCHAR2(12),
            phone VARCHAR2(20)
        )
    """)
    db_client.execute("INSERT INTO test_sm07 VALUES (1, '772456789012', '79161234567')")
    db_client.commit()
    
    # 2. Регистрируем колонки в профиле
    db_client.execute("DELETE FROM PFLB_VIEWCONTENT WHERE table_name = 'TEST_SM07'")
    db_client.execute("""
        INSERT INTO PFLB_VIEWCONTENT (owner_name, table_name, column_name, encode_method, column_encode_type)
        VALUES ('SMOKE_TEST', 'TEST_SM07', 'INN', 'HASH', 'INNUMBER')
    """)
    db_client.execute("""
        INSERT INTO PFLB_VIEWCONTENT (owner_name, table_name, column_name, encode_method, column_encode_type)
        VALUES ('SMOKE_TEST', 'TEST_SM07', 'PHONE', 'HASH', 'PHONENUMBER')
    """)
    db_client.commit()
    
    test_logger.info("SM-07: запуск деперсонализации")
    
    # 3. Вызов процедуры (синхронный, джобы внутри)
    try:
        db_client.execute("""
            BEGIN
                PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                    '70FCD8-DA7721-A47226-9C2ED7',   -- лицензионный ключ
                    'HASH',                          -- метод (HASH для всех)
                    1,                               -- threads
                    1000,                            -- rows per update
                    0,                               -- simulate
                    1,                               -- thread per dechannel
                    1,                               -- de_channel
                    1                                -- as_channel
                );
            END;
        """)
        db_client.commit()
    except Exception as e:
        test_logger.error(f"Деперсонализация упала: {e}")
        pytest.fail(f"Ошибка при вызове PFLB_PROCESS_DATA_TYPE: {e}")
    
    # 4. Проверка, что в логах есть запись об успешном завершении
    log_count = db_client.fetch_scalar("""
        SELECT COUNT(*) FROM PFLB_LOGS
        WHERE LSTR LIKE '%exit from generate_update%'
    """)
    assert log_count > 0, "В логах нет сообщения об успешном завершении"
    
    # 5. Проверка, что данные изменились
    inn_after = db_client.fetch_scalar("SELECT inn FROM test_sm07 WHERE id = 1")
    assert inn_after != '772456789012', "ИНН не был обезличен"
    
    # 6. Очистка
    db_client.execute("DROP TABLE test_sm07 PURGE")
    db_client.commit()
    test_logger.info("SM-07: пройден")