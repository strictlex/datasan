from pathlib import Path

def test_masking_method_scale(db_client, tmp_path, cleanup, test_logger, method_config):
    test_logger.info("Запуск масштабного теста для метода %s", method_config["function"])
    tester = MethodTester(db_client, method_config) # type: ignore
    
    # Создаём постоянную папку для отчётов
    reports_dir = Path.cwd() / "reports"
    reports_dir.mkdir(exist_ok=True)
    
    count_table_rows = 100
    success = tester.run(rows=count_table_rows, report_dir=reports_dir)
    assert success, f"Метод {method_config['function']} не прошёл валидацию для всех строк"
    test_logger.info("Метод %s успешно протестирован на %d строк", method_config["function"], count_table_rows)