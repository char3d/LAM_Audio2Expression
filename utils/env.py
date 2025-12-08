"""
The code is base on https://github.com/Pointcept/Pointcept
"""

import os
import random
import numpy as np
import torch
import torch.backends.cudnn as cudnn

from datetime import datetime


def get_random_seed():
    seed = (
        os.getpid()
        + int(datetime.now().strftime("%S%f"))
        + int.from_bytes(os.urandom(2), "big")
    )
    return seed


def set_seed(seed=None):
    if seed is None:
        seed = get_random_seed()
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    # Only touch CUDA/CuDNN when available
    if torch.cuda.is_available():
        torch.cuda.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
        cudnn.benchmark = False
        cudnn.deterministic = True
    os.environ["PYTHONHASHSEED"] = str(seed)


# New: unified device selector supporting Apple MPS, CUDA, and CPU
def get_torch_device(prefer_mps: bool = True) -> torch.device:
    """
    Returns a torch.device in the following priority:
    1) MPS (Apple Silicon) if available and prefer_mps=True
    2) CUDA if available
    3) CPU
    """
    try:
        if prefer_mps and hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            return torch.device("mps")
    except Exception:
        # Fallback if MPS backend probing fails
        pass

    if torch.cuda.is_available():
        return torch.device("cuda")

    return torch.device("cpu")
