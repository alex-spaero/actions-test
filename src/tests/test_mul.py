from action import mul


def test_mul():
    assert mul([1, 2, 3], [4, 5, 6]) == [4, 10, 18]
