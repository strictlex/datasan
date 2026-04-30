"""Юнит-тесты на сплиттер SQL-скриптов (без подключения к БД)."""
from utils.sql_runner import split_statements


def test_split_semicolon_basic():
    script = "SELECT 1; SELECT 2;"
    assert split_statements(script, ";") == ["SELECT 1", "SELECT 2"]


def test_split_semicolon_ignores_quoted():
    script = "INSERT INTO t VALUES ('a;b'); SELECT 1;"
    assert split_statements(script, ";") == [
        "INSERT INTO t VALUES ('a;b')",
        "SELECT 1",
    ]


def test_split_semicolon_ignores_line_comments():
    script = "SELECT 1; -- комментарий; с точкой с запятой\nSELECT 2;"
    parts = split_statements(script, ";")
    assert len(parts) == 2
    assert parts[0].startswith("SELECT 1")
    assert parts[1].strip().endswith("SELECT 2")


def test_split_go_mssql():
    script = "CREATE TABLE t(x INT)\nGO\nINSERT INTO t VALUES (1)\nGO"
    assert split_statements(script, "GO") == [
        "CREATE TABLE t(x INT)",
        "INSERT INTO t VALUES (1)",
    ]


def test_split_go_case_insensitive():
    script = "SELECT 1\ngo\nSELECT 2\nGo"
    assert split_statements(script, "GO") == ["SELECT 1", "SELECT 2"]


def test_split_sqlplus_plsql_block():
    script = (
        "BEGIN\n"
        "  NULL;\n"
        "END;\n"
        "/\n"
        "CREATE TABLE t (x NUMBER);\n"
    )
    parts = split_statements(script, "sqlplus")
    assert len(parts) == 2
    assert parts[0].startswith("BEGIN")
    assert "CREATE TABLE" in parts[1]
