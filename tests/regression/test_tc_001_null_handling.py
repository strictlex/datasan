"""Шаблон регрессионного теста — показывает, как навесить маркер."""
import pytest


@pytest.mark.regression
def test_tc_001_null_in_field_does_not_crash(
    db_client,
    sql_runner,
    inspector,
    test_logger):

    """TC-001 (null-handling): NULL в обезличиваемом поле не должен вызывать ошибку."""

    # 1. Подготовка окружения (AAA: Arrange)
    test_logger.info("TC-001: Создаю тестовую таблицу с NULL-значением")

    # Используем inline SQL для простоты и наглядности
    # В будущем сложные скрипты можно вынести в отдельные .sql файлы

    # В начале теста, перед CREATE
    db_client.execute("""
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE test_null_handling PURGE';
            EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE != -942 THEN RAISE; END IF;  -- -942 = таблица не существует
        END;
    """)
    db_client.execute("COMMIT")

    db_client.execute("""
        CREATE TABLE test_null_handling (
            id NUMBER PRIMARY KEY,
            sensitive_data VARCHAR2(100)
        )
    """)
    db_client.execute("INSERT INTO test_null_handling VALUES (1, NULL)")
    db_client.execute("COMMIT")

    assert inspector.table_exists("TEST_NULL_HANDLING"), "Таблицы не была создана!"

    # 2. Действие (AAA: Act)
    test_logger.info("TC_001: Запуск маскирования...")
    # В реальном тесте здесь будет вызов API или процедуры DataSan.
    # Пока что это заглушка, которую мы заменим позже.
    # run_masking(db_client, "test_profile")
    
    # 3. Проверка (AAA: Assert)
    # Проверяем, что NULL остался NULL (или, если ожидается другое поведение, корректируем ассерт)
    result = db_client.fetch_one("SELECT sensitive_data FROM test_null_handling WHERE id = 1")
    assert result[0] is None, f'Ожидался NULL, но получено: {result[0]}'
    test_logger.info("TC_001: Проверка пройдена успешно.")

    # 4. Очистка (Teardown)
    # Важно: всегда убирать за собой, чтобы тесты были изолированными
    db_client.execute("DROP TABLE test_null_handling PURGE")
    db_client.execute("COMMIT")