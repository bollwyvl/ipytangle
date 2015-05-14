from IPython.utils import traitlets

from .widgets import Tangle


__all__ = ["Tangle", "tangle"]


def tangle(**kwargs):
    new_traitlets = {}

    for key, value in kwargs.items():
        if isinstance(value, int):
            new_traitlets[key] = traitlets.Int(value, sync=True)

    new_class = type(
        'DynamicTangle',
        (Tangle,),
        new_traitlets
    )
    return new_class()
