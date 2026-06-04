import csv
import os
import re
import pytest
import yaml

REPORT_FILE = os.path.join(os.path.dirname(__file__), '../../reports/masking_report.csv')


def load_config():
    config_path = os.path.join(os.path.dirname(__file__), '..', '..', 'masking_config.yaml')
    with open(config_path, 'r', encoding='utf-8') as f:
        return yaml.safe_load(f)['methods']


def save_report(results):
    os.makedirs(os.path.dirname(REPORT_FILE), exist_ok=True)
    with open(REPORT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, delimiter='|')
        writer.writerow(['Function', 'Input', 'Output', 'Validation'])
        for row in results:
            writer.writerow([
                row['function'],
                row['input'],
                row['output'],
                'PASSED' if row['passed'] else 'FAILED'
            ])


@pytest.fixture(scope='session')
def masking_results():
    return []


@pytest.mark.parametrize('method_config', load_config())
def test_masking_method(db_client, method_config, masking_results, test_logger):
    function = method_config['function']
    input_value = method_config['input']
    pattern = method_config.get('pattern')            # может быть None
    check_change = method_config.get('check_change', True)
    use_date = method_config.get('use_date', False)   # новый ключ для дат

    # Строим SQL с учётом типа данных
    if use_date:
        sql = f"SELECT {function}(TO_DATE(:val, 'YYYY-MM-DD')) FROM dual"
    else:
        sql = f"SELECT {function}(:val) FROM dual"

    result = db_client.fetch_one(sql, {'val': input_value})
    output_value = result[0] if result else None

    # Валидация
    passed = True

    # Проверка изменения значения (если требуется)
    if check_change and str(output_value) == str(input_value):
        passed = False

    # Проверка по регулярному выражению (если задано)
    if pattern is not None:
        if not re.match(pattern, str(output_value)):
            passed = False

    test_logger.info(f"{function}({input_value}) -> {output_value} | {'PASS' if passed else 'FAIL'}")

    masking_results.append({
        'function': function,
        'input': input_value,
        'output': str(output_value),
        'passed': passed
    })

    assert passed, f"{function}: {input_value} -> {output_value} не прошёл валидацию"


@pytest.fixture(scope='session', autouse=True)
def generate_report(masking_results):
    yield
    save_report(masking_results)