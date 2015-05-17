from IPython.html import widgets
from IPython.utils import traitlets

__all__ = ["Tangle"]

_dummy = widgets.DOMWidget()

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
    _tangle_upstream_traits = traitlets.Tuple(tuple(_dummy.trait_names()),
                                              sync=True)

    def __init__(self, *args, **kwargs):
        super(Tangle, self).__init__(*args, **kwargs)
