import inspect

from IPython.utils.traitlets import (
    Any,
    CInt,
    CBool,
    CFloat,
    Dict,
    Tuple,
    link,
)

from IPython.html.widgets import Widget
from IPython.html.widgets.widget_selection import _Selection

from .widgets import Tangle

__all__ = ["Tangle", "tangle"]


function = type(lambda: 0)


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

    def _refresh(self):
        for key, fn_subscribed in self._derived.items():
            fn, subscribed = fn_subscribed
            for sub in subscribed:
                val = getattr(self, sub)
                self._notify_trait(sub, val, val)
        return self


def _get_primitive(value):
    if isinstance(value, int):
        return CInt
    elif isinstance(value, bool):
        return CBool
    elif isinstance(value, float):
        return CFloat
    elif isinstance(value, dict):
        return Dict


def _link_widget(key, value, class_attrs):
    widget_cls = value.__class__
    traitlet_cls = getattr(widget_cls, "value").__class__

    if isinstance(value, _Selection):
        label_key = "{}_label".format(key)
        options_key = "{}_label_options".format(key)

        class_attrs["_links"] += [
            (label_key, (value, "selected_label")),
        ]

        class_attrs["_dlinks"] += [
            (key, (value, "value")),
            (options_key, (value, "_options_labels")),
        ]

        label_cls = getattr(widget_cls, "selected_label").__class__
        class_attrs[label_key] = label_cls(value.selected_label, sync=True)

        options_cls = getattr(widget_cls, "_options_labels").__class__
        class_attrs[options_key] = options_cls(value._options_labels,
                                               sync=True)
    else:
        class_attrs["_links"].append((key, (value, "value")))

    class_attrs[key] = traitlet_cls(sync=True)

    return class_attrs


def tangle(*args, **kwargs):
    """
    Shortcut to create a new, custom Tangle model. Use instead of directly
    subclassing `Tangle`.

    A new, custom Widget class is created, with each of `kwargs` as a traitlet.

    Returns an instance of the new class with default values.

    `kwargs` options
    - primitive types (int, bool, float) will be created as casting versions
      (`CInt`, `CBool`, `CFloat`)
    - a `list` will be created as an `Enum`
    - a `Widget` instance will create a link to that widget's `value`
    - a `tuple` `(widget_instance, "traitlet")` will create a `link`
    - functions will be `inspect`ed to find their argument names subscribed for
      update... this uses `inspect`, won't work with `*` magic
      - a `tuple` `(function, default)` will be created as the type (as
        above)
    """

    class_attrs = {
        "_links": [],
        "_dlinks": [],
        "_derived": {}
    }

    for value in args:
        if isinstance(value, function):
            # we'll just go ahead and assume this was made by `interact`
            if hasattr(value, "widget") and hasattr(value.widget, "children"):
                for child in value.widget.children:
                    _link_widget(child.description, child, class_attrs)

    for key, value in kwargs.items():
        traitlet_cls = _get_primitive(value)
        traitlet_args = [value]
        traitlet_kwargs = {
            "sync": True
        }

        handled = False

        if traitlet_cls is not None:
            pass
        elif isinstance(value, list):
            traitlet_cls = Any
            traitlet_args = [value[0]]
            class_attrs["{}_options".format(key)] = Tuple(value, sync=True)
        elif isinstance(value, Widget):
            _link_widget(key, value, class_attrs)
            handled = True
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
                traitlet_cls = _get_primitive(example)

                subscribed = inspect.getargspec(fn).args

                class_attrs["_derived"][key] = (fn, subscribed)

        if not handled:
            if traitlet_cls is None:
                raise ValueError("Didn't understand {}: {}".format(key, value))
            class_attrs[key] = traitlet_cls(*traitlet_args, **traitlet_kwargs)

    new_class = type(
        'DynamicAutoTangle{}'.format(id(class_attrs)),
        (AutoTangle,),
        class_attrs
    )

    inst = new_class()
    return inst._refresh()
