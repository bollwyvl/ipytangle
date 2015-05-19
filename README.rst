
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

    tangle(cookies=3, calories=lambda cookies: cookies * 50)

Would connect to this markdown:

.. code:: markdown

    When you eat [`cookies` cookies](#:cookies), you consume [`calories` calories](#:calories).

Would give you something like this:

    When you eat ```2`` cookies <#:cookies>`__, you consume ```150``
    calories <#:>`__.

And interacting with the links would cause the result to update.

See `the examples <./examples>`__!

Screenshot
----------

    TODO

Markdown
~~~~~~~~

``ipytangle`` implements most of
`TangleKit <https://github.com/worrydream/Tangle/blob/master/TangleKit/TangleKit.js>`__
baseline as markdown links. Unrendered tangle markdown should still
render in a useful way:

    templates
    ~~~~~~~~~

    Backticks, **\`\`** are used to represent a JavaScript expression
    that will be updated on interaction (or cascading updates). In
    addition to any variables defined with ``ipytangle``, some
    `formatting <#Formatting>`__ libraries are provided. ``window``
    globals should also work :wink:.

    Only the generated ``code`` will be transformed, the rest of the
    elements (if any) will be preserved.

-  just display a field

   .. code:: markdown

       For [`years` years](#:) have I trained Jedi. 

-  display and update an integer based on dragging

   .. code:: markdown

       [made the kessel run in `distance` parsecs](#:distance)

-  mark some text (which may have other fields) to only display based on
   condition

   .. code:: markdown

       What's more foolish? The [`fool_is_more_foolish`](#:if)fool[](#:else)the fool who follows him(#:endif).

   you may also have an ``else`` and any number of ``elsif``\ s...
   because they are markdown span-level elements, you may use newlines
   for easier editing

   .. code:: markdown

       [`feeling == "bad"`](#:if) I have a bad feeling about this.
       [`feeling == "cautious"`](#:elif) You will never find a more wretched hive of scum and villainy.
       [](#:else) Search your feelings.
       [](#:endif)

Backend
~~~~~~~

-  connects to any IPython widget

Formatting
~~~~~~~~~~

-  bundles several nice libraries and shortcuts for formatting text:
-  `moment <http://momentjs.com/>`__ dates and times
-  `mathjs <http://mathjs.org/>`__ scientific units
-  `numeral <http://numeraljs.com/>`__ currency, and miscellany

Inspiration
-----------

Of course, Brett Victor's `Tangle <http://worrydream.com/Tangle/>`__ is
the primary inspiration, as well as: -
`tributary <http://tributary.io/>`__ - `derby <http://derbjys.org>`__ -
`d3 <http://d3js.org>`__

Roadmap
-------

-  support
   `TangleKit <https://github.com/worrydream/Tangle/blob/master/TangleKit/TangleKit.js>`__
   baseline
-  float
-  switch
-  :math:`L_AT^EX` (sic)
-  sparklines, distributions, etc.
