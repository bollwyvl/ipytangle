import inspect

from IPython.utils.traitlets import (
    Any,
    CInt,
    CBool,
    CFloat,
    Enum,
    Tuple,
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

        for key, fn_subscribed in self._derived.items():
            self._subscribe(key, fn_subscribed)

    def _subscribe(self, key, fn_subscribed):
        fn, subscribed = fn_subscribed

        def _handler():
            handler_kwargs = {sub: getattr(self, sub) for sub in subscribed}
            setattr(self, key, fn(**handler_kwargs))

        self.on_trait_change(_handler, name=subscribed)



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
      - a `tuple` `(function, default)` will be created as the type (as
        above)
    """

    class_attrs = {
        "_links": [],
        "_derived": {}
    }

    def get_primitive(value):
        if isinstance(value, int):
            return CInt
        elif isinstance(value, bool):
            return CBool
        elif isinstance(value, float):
            return CFloat


    for key, value in kwargs.items():
        traitlet_cls = get_primitive(value)
        traitlet_args = [value]
        traitlet_kwargs = {
            "sync": True
        }

        if traitlet_cls is not None:
            pass
        elif isinstance(value, list):
            traitlet_cls = Enum
            traitlet_kwargs["default_value"] = value[0]
            class_attrs["_{}_choices".format(key)] = Tuple(value, sync=True)
        elif isinstance(value, tuple):
            if isinstance(value[0], Widget):
                widget, traitlet = value
                widget_cls = widget.__class__
                traitlet_args = []
                traitlet_cls = getattr(widget_cls, traitlet).__class__
                class_attrs["_links"].append((key, value))
            elif hasattr(value[1], "__call__"):
                example, fn = value
                traitlet_args = [example]
                traitlet_cls = get_primitive(example)

                subscribed = inspect.getargspec(fn).args

                class_attrs["_derived"][key] = (fn, subscribed)

        if traitlet_cls is None:
            raise ValueError("Didn't understand {}: {}".format(key, value))
        class_attrs[key] = traitlet_cls(*traitlet_args, **traitlet_kwargs)

    new_class = type(
        'DynamicAutoTangle{}'.format(id(class_attrs)),
        (AutoTangle,),
        class_attrs
    )

    return new_class()
