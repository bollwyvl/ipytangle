from IPython.utils.traitlets import (
    Any,
    CInt,
    CBool,
    CFloat,
    Enum,
    link,
)

from IPython.html.widgets import Widget

from .widgets import Tangle


__all__ = ["Tangle", "tangle"]


class AutoTangle(Tangle):
    def __init__(self, *args, **kwargs):
        super(AutoTangle, self).__init__(*args, **kwargs)

        for key, widget_traitlet in self._links:
            link((self, key), widget_traitlet)


def tangle(**kwargs):
    """
    Shortcut to create a new, custom Tangle model. Use instead of directly
    subclassing `Tangle`.

    A new, custom Widget class is created, with each of `kwargs` as a traitlet.

    Returns an instance of the new class with default values.

    `kwargs` options
    - primitive types (int, bool, float) will be created as casting versions
      (`CInt`, `CBool`, `CFloat`)
    - a `list` will be created as an `Enum`
    - a `tuple` `(widget_instance, "traitlet")` will create a `link`
    - functions will be `inspect`ed to find their argument names subscribed for
      update... this uses `inspect`, won't work with `*` magic
      - a lone function will be created as `Any`
      - a `tuple` `(type, function)` will be created as the type (as above)
    """

    class_attrs = {
        "_links": []
    }

    types = {
        (int, CInt),
        (bool, CBool),
        (float, CFloat),
        (list, Enum, lambda x: {"default_value": x[0]})
    }

    for key, value in kwargs.items():
        traitlet_cls = Any
        traitlet_args = [value]
        traitlet_kwargs = {
            "sync": True
        }

        if isinstance(value, int):
            traitlet_cls = CInt
        elif isinstance(value, bool):
            traitlet_cls = CBool
        elif isinstance(value, float):
            traitlet_cls = CFloat
        elif isinstance(value, list):
            traitlet_cls = Enum
            traitlet_kwargs["default_value"] = value[0]
        elif isinstance(value, tuple):
            if isinstance(value[0], Widget):
                widget, traitlet = value
                widget_cls = widget.__class__
                class_attrs["_links"].append((key, value))
                traitlet_args = []
                traitlet_cls = getattr(widget_cls, traitlet).__class__

        class_attrs[key] = traitlet_cls(*traitlet_args, **traitlet_kwargs)

    new_class = type(
        'DynamicAutoTangle{}'.format(id(class_attrs)),
        (AutoTangle,),
        class_attrs
    )

    return new_class()
