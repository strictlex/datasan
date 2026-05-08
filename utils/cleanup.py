"""
Cleanup-контекст для тестов.

Типовая проблема: тест создал таблицу, упал на assert'е — таблица осталась,
следующий запуск падает на CREATE. Фикстура даёт объект, которому можно
регистрировать finalize-колбэки; они выполнятся в teardown в обратном порядке.

Использование:
    def test_x(db_client, cleanup):
        from utils.data_factory import create_and_populate, drop_if_exists, TestTableSpec
        spec = TestTableSpec(name="t_profile_01")
        create_and_populate(db_client, spec)
        cleanup.add(lambda: drop_if_exists(db_client, spec.name))
        ...
"""
from __future__ import annotations

from typing import Callable

from utils.logger import get_logger

log = get_logger(__name__)


class Cleanup:
    def __init__(self):
        self._callbacks: list[Callable[[], None]] = []

    def add(self, fn: Callable[[], None]) -> None:
        self._callbacks.append(fn)

    def run(self) -> None:
        # LIFO — удаляем в обратном порядке создания (как stack)
        while self._callbacks:
            fn = self._callbacks.pop()
            try:
                fn()
            except Exception as e:  # noqa: BLE001
                log.warning("Cleanup callback упал, игнорирую: %s", e)
