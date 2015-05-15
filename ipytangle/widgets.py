from IPython.html import widgets
from IPython.utils import traitlets


class Tangle(widgets.DOMWidget):
    _view_name = traitlets.Unicode('TangleView', sync=True)
    _view_module = traitlets.Unicode('/nbextensions/ipytangle/tangle_view.js', sync=True)

    _tangle_prefix = traitlets.Unicode('', sync=True)
