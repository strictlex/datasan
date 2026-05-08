"""Юнит-тесты генераторов синтетических ПДн (без подключения к БД)."""
import random

from utils.data_factory import inn_12, phone_ru, passport_ru, full_name


def _inn12_checksum_ok(inn: str) -> bool:
    """Эталонная проверка контрольных цифр 12-значного ИНН."""
    if len(inn) != 12 or not inn.isdigit():
        return False
    d = [int(c) for c in inn]
    w1 = [7, 2, 4, 10, 3, 5, 9, 4, 1, 3]
    n11 = sum(d[i] * w1[i] for i in range(10)) % 11 % 10
    w2 = [3, 7, 2, 4, 10, 3, 5, 9, 4, 1, 3]
    n12 = sum(d[i] * w2[i] for i in range(11)) % 11 % 10
    return d[10] == n11 and d[11] == n12


def test_inn_checksum_valid_for_many_seeds():
    for seed in range(100):
        rng = random.Random(seed)
        inn = inn_12(rng)
        assert _inn12_checksum_ok(inn), f"Невалидный ИНН {inn} для seed={seed}"


def test_inn_is_deterministic():
    a = inn_12(random.Random(42))
    b = inn_12(random.Random(42))
    assert a == b, "Один и тот же seed должен давать один и тот же ИНН"


def test_phone_format():
    phone = phone_ru(random.Random(0))
    assert phone.startswith("+79") and len(phone) == 12 and phone[1:].isdigit()


def test_passport_format():
    p = passport_ru(random.Random(0))
    parts = p.split(" ")
    assert len(parts) == 2
    assert len(parts[0]) == 4 and parts[0].isdigit()
    assert len(parts[1]) == 6 and parts[1].isdigit()


def test_full_name_has_two_words():
    name = full_name(random.Random(0))
    assert len(name.split()) == 2
