"""Шаблон регрессионного теста — показывает, как навесить маркер."""
import pytest


@pytest.mark.regression
def test_placeholder_regression(test_logger):
    test_logger.info("Заглушка регресса — замени на реальные проверки.")
    assert True
