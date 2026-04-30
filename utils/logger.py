"""
Единый логгер. Пишет одновременно в stdout (через pytest live log)
и в файл logs/run-<timestamp>.log.
"""
from __future__ import annotations

import logging
from datetime import datetime
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
LOGS_DIR = ROOT_DIR / "logs"
LOGS_DIR.mkdir(exist_ok=True)

_FORMAT = "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
_DATEFMT = "%Y-%m-%d %H:%M:%S"
_initialized = False


def setup_logging(level: int = logging.INFO) -> Path:
    """Инициализирует корневой логгер. Возвращает путь к файлу лога."""
    global _initialized

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_file = LOGS_DIR / f"run-{timestamp}.log"

    if _initialized:
        return log_file

    root = logging.getLogger()
    root.setLevel(level)

    # Pytest сам добавит консольный хендлер при log_cli=true,
    # от нас нужен только файловый.
    fh = logging.FileHandler(log_file, encoding="utf-8")
    fh.setFormatter(logging.Formatter(_FORMAT, datefmt=_DATEFMT))
    fh.setLevel(level)
    root.addHandler(fh)

    _initialized = True
    return log_file


def get_logger(name: str) -> logging.Logger:
    return logging.getLogger(name)
