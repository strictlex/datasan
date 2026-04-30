# datasan-tests

Автотесты для DataSan. Поддерживаемые СУБД: Oracle, PostgreSQL, MS SQL Server.

## Быстрый старт

```bash
# 1. Установить зависимости
pip install -r requirements.txt

# 2. Скопировать шаблон конфига и заполнить креды в .env
cp .env.example .env
# отредактировать .env

# 3. Запустить smoke-набор на Oracle
pytest -m smoke --db=oracle

# Другие варианты
pytest -m smoke --db=postgres
pytest -m regression --db=mssql
pytest -m "smoke or regression" --db=oracle
pytest tests/custom/ --db=oracle     # произвольный набор
```

## Структура

```
datasan-tests/
├── config/
│   └── databases.yaml        # профили подключений (без паролей)
├── sql/
│   ├── oracle/
│   │   ├── install/          # скрипты установки DataSan
│   │   └── drop/             # скрипты удаления
│   ├── postgres/
│   └── mssql/
├── tests/
│   ├── smoke/                # smoke-тесты (@pytest.mark.smoke)
│   ├── regression/           # регресс (@pytest.mark.regression)
│   └── custom/               # произвольные тесты
├── utils/
│   ├── db/                   # клиенты СУБД (фабрика + реализации)
│   ├── sql_runner.py         # исполнение .sql-файлов
│   ├── schema_inspector.py   # проверка наличия объектов
│   ├── config.py             # загрузка конфига
│   └── logger.py             # единый логгер
├── conftest.py               # фикстуры pytest
├── pytest.ini                # маркеры, junitxml
├── .env.example
└── requirements.txt
```

## Добавить новый тест

1. Положить файл `test_sm_XX_<название>.py` в `tests/smoke/`.
2. Повесить маркер: `@pytest.mark.smoke`.
3. Запросить нужные фикстуры: `db_client`, `sql_runner`, `inspector`, `test_logger`.

Пример:
```python
import pytest

@pytest.mark.smoke
def test_sm_XX_check_something(db_client, inspector, test_logger):
    test_logger.info("Проверяем наличие таблицы PFLB_LOGS")
    assert inspector.table_exists("PFLB_LOGS")
```

## Отчёты

JUnit XML пишется в `reports/junit-<db>-<timestamp>.xml` — это тот же формат,
который понимает TestIT и большинство TMS. Логи — в `logs/run-<timestamp>.log`.
