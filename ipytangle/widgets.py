from IPython.html import widgets
from IPython.utils import traitlets

__all__ = ["Tangle"]


class TangleBase(widgets.DOMWidget):
    pass


class Tangle(TangleBase):
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

    # compatibilty with core types (interact)
    description = traitlets.Unicode("Tangle", sync=True)
    value = traitlets.Instance(sync=True, klass=TangleBase)

    # for the future?
    _tangle_prefix = traitlets.Unicode("", sync=True)
    _tangle_upstream_traits = traitlets.Tuple(
        sync=True
    )
    _tangle_cell_hiding = traitlets.Bool(
        sync=True
    )

    def __init__(self, *args, **kwargs):
        _dummy = widgets.DOMWidget()
        kwargs["_tangle_upstream_traits"] = tuple(_dummy.trait_names())
        super(Tangle, self).__init__(*args, **kwargs)
        self.value = self
        self.on_trait_change(self._notify_value)

    def _notify_value(self, name, old, new):
        if name != "value":
            self._notify_trait("value", self, self)
