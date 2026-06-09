import pytest

@pytest.mark.smoke
def test_sm_14_integrity(db_client, test_logger):
    test_logger.info("SM-14: проверка целостности обработанных таблиц")
    # НЕ вызываем PFLB_PROCESS_DATA_TYPE повторно!
    # Просто проверяем, что таблицы из VIEWCONTENT есть в PROCESSED_TABLES
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