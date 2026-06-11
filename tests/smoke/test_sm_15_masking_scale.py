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
def test_masking_method_scale(db_client, tmp_path, cleanup, test_logger, method_config):
    test_logger.info("Запуск масштабного теста для метода %s", method_config["function"])
    tester = MethodTester(db_client, method_config)
    
    # Создаём постоянную папку для отчётов
    reports_dir = Path.cwd() / "reports"
    reports_dir.mkdir(exist_ok=True)
    count_rows = 10000
    success = tester.run(rows=count_rows, report_dir=reports_dir)
    assert success, f"Метод {method_config['function']} не прошёл валидацию для всех строк"
    test_logger.info("Метод %s успешно протестирован на %d строк", method_config["function"], count_rows)