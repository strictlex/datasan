"""
Исполнение .sql-файлов на целевой СУБД.

Этот runner поддерживает три режима разделения через `separator`:
- "sqlplus" — Oracle: блоки делятся "/" на отдельной строке,
              вне блоков — ";" в конце строки.
- "GO"      — MSSQL.
- ";"       — прочие: простое разбиение по ";".
"""
from __future__ import annotations

import re
from pathlib import Path

from utils.db.base import DBClient
from utils.logger import get_logger

log = get_logger(__name__)

def _split_sqlplus(script: str) -> list[str]:
    """
    Разделитель в стиле SQL*Plus.
    """
    import re
    # Нормализуем: вставляем перенос перед разделителем если прилеплен к коду
    script = re.sub(r'(?<!\n)(/ --HARDCODE FOR DEPLOYMENT)', r'\n\1', script)

    statements: list[str] = []
    buf: list[str] = []

    for line in script.splitlines():
        stripped = line.strip()
        if stripped == "/" or stripped.startswith("/ "):
            stmt = "\n".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
        else:
            buf.append(line)


    tail = "\n".join(buf).strip()
    if tail:
        first_word = tail.lstrip().split()[0].upper() if tail.strip() else ""
        plsql_keywords = {
            "CREATE", "DECLARE", "BEGIN",
        }
        # Проверяем что это PL/SQL-блок а не простой DDL
        is_plsql = False
        if first_word in plsql_keywords:
            upper_tail = tail.upper()
            for kw in ("PACKAGE", "PACKAGE BODY", "PROCEDURE", "FUNCTION",
                       "TRIGGER", "TYPE", "BEGIN"):
                if kw in upper_tail[:100]:
                    is_plsql = True
                    break
        if is_plsql:
            statements.append(tail)
        else:
            for part in _split_semicolon(tail):
                statements.append(part)

    return statements

def _split_go(script: str) -> list[str]:
    """MSSQL: 'GO' на отдельной строке."""
    statements: list[str] = []
    buf: list[str] = []
    for line in script.splitlines():
        if re.match(r"^\s*GO\s*$", line, flags=re.IGNORECASE):
            stmt = "\n".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
        else:
            buf.append(line)
    tail = "\n".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


def _split_semicolon(script: str) -> list[str]:
    # Простое разбиение, игнорируя ";" внутри кавычек и комментариев.
    statements: list[str] = []
    buf: list[str] = []
    in_single = in_double = False
    i = 0
    while i < len(script):
        ch = script[i]
        # строчный комментарий
        if not in_single and not in_double and ch == "-" and script[i:i+2] == "--":
            # до конца строки
            nl = script.find("\n", i)
            if nl == -1:
                buf.append(script[i:])
                break
            buf.append(script[i:nl])
            i = nl
            continue
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        if ch == ";" and not in_single and not in_double:
            stmt = "".join(buf).strip()
            if stmt:
                statements.append(stmt)
            buf = []
        else:
            buf.append(ch)
        i += 1
    tail = "".join(buf).strip()
    if tail:
        statements.append(tail)
    return statements


def split_statements(script: str, separator: str) -> list[str]:
    if separator == "sqlplus":
        return _split_sqlplus(script)
    if separator.upper() == "GO":
        return _split_go(script)
    return _split_semicolon(script)


class SQLRunner:
    def __init__(self, client: DBClient, separator: str = ";"):
        self.client = client
        self.separator = separator

    def run_script(self, path: Path) -> int:
        """Выполняет .sql-файл. Возвращает количество успешно применённых statement'ов."""
        log.info("Выполняю SQL-скрипт: %s", path)
        text = path.read_text(encoding="utf-8")
        statements = split_statements(text, self.separator)
        log.debug("Statement'ов в скрипте: %d", len(statements))
        for idx, stmt in enumerate(statements, 1):
            preview = stmt.splitlines()[0][:120]
            log.debug("  [%d/%d] %s…", idx, len(statements), preview)
            self.client.execute(stmt)
        return len(statements)

    def run_dir(self, dir_path: Path, pattern: str = "*.sql") -> int:
        """Выполняет все .sql-файлы в каталоге по алфавиту"""
        files = sorted(dir_path.glob(pattern))
        if not files:
            log.warning("В каталоге %s нет файлов по маске %s", dir_path, pattern)
            return 0
        total = 0
        for f in files:
            total += self.run_script(f)
        return total
