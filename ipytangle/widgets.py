from IPython.html import widgets
from IPython.utils import traitlets


class Tangle(widgets.DOMWidget):
    """
    The base Tangle class: subclass this if you know your way around
    `traitlets`.

    Otherwise, check out `tangle`.
    """
    _view_name = traitlets.Unicode('TangleView', sync=True)
    _view_module = traitlets.Unicode('/nbextensions/ipytangle/tangle_view.js',
                                     sync=True)

    # for the future?
    _tangle_prefix = traitlets.Unicode('', sync=True)
