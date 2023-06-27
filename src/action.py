from typing import List

import numpy as np


def mul(arr1: List[float], arr2: List[float]) -> List[float]:
    return list(np.array(arr1) * np.array(arr2) * 2)
