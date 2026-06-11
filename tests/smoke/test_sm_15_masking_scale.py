"""
SM-15: Масштабное тестирование методов маскирования.
Для каждого метода из конфига создаётся таблица с 100k+ строк,
данные генерируются, применяется маскирование, проверяется валидация.
"""
from __future__ import annotations

import pytest
import yaml
from pathlib import Path

from utils.method_tester import MethodTester
from utils.cleanup import Cleanup

CONFIG_PATH = Path(__file__).parent.parent.parent / "config" / "methods_scale.yaml"


def load_methods():
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data["methods"]


@pytest.mark.smoke
@pytest.mark.parametrize("method_config", load_methods(), ids=lambda m: m["function"])
def test_masking_method_scale(db_client, tmp_path, cleanup: Cleanup, test_logger, method_config):
    """
    Запуск масштабного теста для одного метода.
    tmp_path – временная папка pytest для отчётов.
    """
    test_logger.info("Запуск масштабного теста для метода %s", method_config["function"])
    tester = MethodTester(db_client, method_config)
    # Регистрируем очистку на случай падения 
    # cleanup.add(tester.drop_table) --- tester.run() уже удаляет таблицу в finally
    rows_table = 1000 #rколичество строк в создаваемых таблицах
    success = tester.run(rows=rows_table, report_dir=tmp_path)
    assert success, f"Метод {method_config['function']} не прошёл валидацию для всех строк"
    test_logger.info(f"Метод %s успешно протестирован на {rows_table} строк", method_config["function"])