"""
SM-14: Проверка целостности после деперсонализации (минимальная).
Убеждаемся, что все активные таблицы из PFLB_VIEWCONTENT обработаны и есть в PFLB_PROCESSED_TABLES.
"""
import pytest
import os

@pytest.mark.smoke
def test_sm_14_integrity(db_client, test_logger):
    test_logger.info("SM-14: проверка целостности обработанных таблиц")

    license_key = os.getenv('DATASAN_LICENSE_VALID', 'DUMMY_KEY')
    # Гарантируем, что деперсонализация была выполнена (можно вызывать повторно – идемпотентно)
    db_client.execute(f"""
        BEGIN
            PFLB_PROCESS_DATA_TYPE(1, 100, '{license_key}');
        END;
    """)

    # Ищем таблицы с active=1 (подразумеваем, что колонка active есть; если нет – считаем все)
    # Если колонки active нет, проверяем все записи
    result = db_client.execute("""
        SELECT v.table_name
        FROM PFLB_VIEWCONTENT v
        WHERE NOT EXISTS (
            SELECT 1 FROM PFLB_PROCESSED_TABLES p
            WHERE p.table_name = v.table_name
        )
    """)
    missing = [row[0] for row in result] if result else []
    assert not missing, f"Следующие таблицы не найдены в PFLB_PROCESSED_TABLES: {missing}"

    test_logger.info("SM-14: целостность подтверждена")