
IPyTangle
=========

Reactive narratives inspired by
`Tangle <http://worrydream.com/Tangle/>`__ in the `Jupyter
Notebook <http://jupyter.org>`__.

IPyTangle makes plain markdown into an interactive part of your
data-driven narrative.

This python:

.. code:: python

    from ipytangle import tangle

    jar = tangle(cookies=3, calories=150)

    @jar.on_trait_change
    def cookies_changed(name, old, new):
        if name is "cookies":
            jar.calories = new * 50

    jar

Could connect to this markdown:

.. code:: markdown

    > When you eat [`cookies` cookies](#:cookies), you consume [`calories` calories](#:calories).

Would give you something like this:

    When you eat ```2`` cookies <#:cookies>`__, you consume ```150``
    calories <#:>`__.

And interacting with the links would cuase the result to update.

TODO: Screenshot
----------------

Features
--------

-  Implements
   `TangleKit <https://github.com/worrydream/Tangle/blob/master/TangleKit/TangleKit.js>`__
   baseline as markdown links
-  read-only just displays a number
   ``markdown     For [`years` years](#:) have I trained Jedi.``
-  update an integer based on dragging
   ``markdown     [made the kessel run in `distance` parsecs](#:distance)``
-  mark some text (which may have other fields) to only display based on
   condition
   ``markdown     What's more foolish? The [`fool_is_more_foolish`](#:if)fool[](#:else)the fool who follows him(#:endif).``

Roadmap
-------

-  support
   `TangleKit <https://github.com/worrydream/Tangle/blob/master/TangleKit/TangleKit.js>`__
   baseline
-  float
-  switch
-  [STRIKEOUT:derived value shortcut]
-  ``jar = tangle(cookies=3, calories=lambda cookies: cookies * 150)``
-  [STRIKEOUT:trait link shortcut]
-  ``jar = tangle(cookies=(package, "cookies"))``
-  :math:`L_AT^EX` (sic)

