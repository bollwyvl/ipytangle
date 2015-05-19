from IPython.html import widgets
from IPython.utils import traitlets

__all__ = ["Tangle"]


class Tangle(widgets.DOMWidget):
    """
    The base Tangle class: subclass this if you know your way around
    `traitlets`.

    Otherwise, check out `tangle`.
    """
    _view_name = traitlets.Unicode("TangleView", sync=True)
    _view_module = traitlets.Unicode(
        "/nbextensions/ipytangle/js/tangle_view.js",
        sync=True
    )

    # for the future?
    _tangle_prefix = traitlets.Unicode("", sync=True)
    _tangle_upstream_traits = traitlets.Tuple(
        sync=True
    )

    def __init__(self, *args, **kwargs):
        _dummy = widgets.DOMWidget()
        kwargs["_tangle_upstream_traits"] = tuple(_dummy.trait_names())
        super(Tangle, self).__init__(*args, **kwargs)
