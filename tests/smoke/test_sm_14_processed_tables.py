import pytest

@pytest.mark.smoke
def test_sm_14_processed_tables(db_client, test_logger):
    """
    SM-14: проверка, что все таблицы из профиля обработаны.
    """
    test_logger.info("SM-14: подготовка двух тестовых таблиц")
    
    # Создаём две таблицы
    for tname in ['TEST_SM14_A', 'TEST_SM14_B']:
        # db_client.execute(f"BEGIN DROP TABLE {tname} PURGE END;")
        try:
            db_client.execute(f"DROP TABLE {tname} PURGE")
        except Exception as e:
            # Таблицы нет — игнорируем
            test_logger.info(f"Таблица {tname} не существовала, пропускаем DROP")
        db_client.execute(f"""
            CREATE TABLE {tname} (
                id NUMBER PRIMARY KEY,
                name VARCHAR2(50)
            )
        """)
        db_client.execute(f"INSERT INTO {tname} VALUES (1, 'original')")
        db_client.commit()
        
        # Регистрируем в профиле
        db_client.execute(f"DELETE FROM PFLB_VIEWCONTENT WHERE table_name = '{tname}'")
        db_client.execute(f"""
            INSERT INTO PFLB_VIEWCONTENT (owner_name, table_name, column_name, encode_method, column_encode_type)
            VALUES ('SMOKE_TEST', '{tname}', 'NAME', 'CHAR', 'CHAR')
        """)
    db_client.commit()
    
    # Запускаем деперсонализацию (можно вызвать один раз для обеих таблиц)
    test_logger.info("SM-14: запуск деперсонализации")
    try:
        db_client.execute("""
            BEGIN
                PFLB_DATASAN.PFLB_PROCESS_DATA_TYPE(
                    '70FCD8-DA7721-A47226-9C2ED7',
                    'CHAR',
                    1,
                    1000,
                    0,
                    1,
                    1,
                    1
                );
            END;
        """)
        db_client.commit()
    except Exception as e:
        test_logger.error(f"Деперсонализация не удалась: {e}")
        pytest.fail(f"Ошибка: {e}")
    
    # Проверяем, что обе таблицы отмечены как PROCESSED
    processed = db_client.fetch_all("""
        SELECT table_name, status
        FROM PFLB_PROCESSED_TABLES
        WHERE owner_name = 'SMOKE_TEST'
          AND table_name IN ('TEST_SM14_A', 'TEST_SM14_B')
    """)
    processed_map = {row[0]: row[1] for row in processed}
    assert processed_map.get('TEST_SM14_A') == 'PROCESSED', "Таблица A не обработана"
    assert processed_map.get('TEST_SM14_B') == 'PROCESSED', "Таблица B не обработана"
    
    # Очистка
    for tname in ['TEST_SM14_A', 'TEST_SM14_B']:
        db_client.execute(f"DROP TABLE {tname} PURGE")
    db_client.commit()
    test_logger.info("SM-14: пройден")