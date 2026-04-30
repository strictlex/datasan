"""
Общие фикстуры и CLI-опции pytest.

Запуск:
    pytest -m smoke --db=oracle
    pytest -m regression --db=postgres
    pytest tests/custom/ --db=mssql

Выбор СУБД:
    1) ключ --db=oracle|postgres|mssql
    2) переменная окружения DATASAN_DB
    3) по умолчанию: oracle
"""
from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path

import pytest

from utils.cleanup import Cleanup
from utils.config import ROOT_DIR, load_config, AppConfig, DBProfile
from utils.db import DBClient, make_client
from utils.logger import setup_logging, get_logger
from utils.schema_inspector import SchemaInspector
from utils.sql_runner import SQLRunner

log = get_logger("conftest")

SUPPORTED_DBS = ("oracle", "postgres", "mssql")


# ---------- CLI options ------------------------------------------------------

def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--db",
        action="store",
        default=None,
        choices=SUPPORTED_DBS,
        help="Целевая СУБД: oracle|postgres|mssql (по умолчанию из env DATASAN_DB, иначе oracle).",
    )


def pytest_configure(config: pytest.Config) -> None:
    # Инициализируем логирование в файл и прописываем junitxml с таймстампом,
    # если пользователь не задал свой --junitxml.
    log_file = setup_logging()
    log.info("Log-файл этого прогона: %s", log_file)

    if not config.option.xmlpath:
        db = _resolve_db_key(config)
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        reports_dir = ROOT_DIR / "reports"
        reports_dir.mkdir(exist_ok=True)
        config.option.xmlpath = str(reports_dir / f"junit-{db}-{ts}.xml")
        log.info("JUnit XML: %s", config.option.xmlpath)


def _resolve_db_key(config: pytest.Config) -> str:
    return (
        config.getoption("--db")
        or os.getenv("DATASAN_DB")
        or "oracle"
    )


# ---------- маркеры: пропуск тестов, не применимых к текущей СУБД ------------

def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    """Если тест помечен @pytest.mark.<db> — запускать его только на этой СУБД."""
    current = _resolve_db_key(config)
    db_only_markers = set(SUPPORTED_DBS)
    for item in items:
        item_db_markers = {m.name for m in item.iter_markers()} & db_only_markers
        if item_db_markers and current not in item_db_markers:
            item.add_marker(
                pytest.mark.skip(reason=f"тест применим только к {item_db_markers}, текущая БД: {current}")
            )


# ---------- core fixtures ----------------------------------------------------

@pytest.fixture(scope="session")
def db_key(request: pytest.FixtureRequest) -> str:
    return _resolve_db_key(request.config)


@pytest.fixture(scope="session")
def app_config(db_key: str) -> AppConfig:
    return load_config(db_key=db_key)


@pytest.fixture(scope="session")
def db_profile(app_config: AppConfig, db_key: str) -> DBProfile:
    return app_config.databases[db_key]


@pytest.fixture
def db_client(app_config: AppConfig, db_profile: DBProfile) -> DBClient:
    """
    Новый клиент на каждый тест — проще рассуждать об изоляции и транзакциях.
    """
    client = make_client(db_profile, connect_timeout=app_config.run.connect_timeout_sec)
    client.connect()
    try:
        yield client
    finally:
        client.close()


@pytest.fixture
def sql_runner(db_client: DBClient, db_profile: DBProfile) -> SQLRunner:
    return SQLRunner(db_client, separator=db_profile.statement_separator)


@pytest.fixture
def inspector(db_client: DBClient, db_profile: DBProfile) -> SchemaInspector:
    return SchemaInspector(db_client, schema=db_profile.schema_)


@pytest.fixture
def sql_dir(db_profile: DBProfile) -> Path:
    """Корень SQL-скриптов для текущей СУБД."""
    return db_profile.sql_dir_abs


@pytest.fixture
def test_logger(request: pytest.FixtureRequest):
    """Логгер с именем текущего теста."""
    return get_logger(f"test.{request.node.name}")


@pytest.fixture
def cleanup():
    """
    Регистратор финализаторов. Вызовы cleanup.add(fn) выполняются в LIFO
    после теста, даже если тест упал.
    """
    c = Cleanup()
    try:
        yield c
    finally:
        c.run()
