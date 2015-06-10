casper.notebook_test ->
  cells = {}

  @viewport 1024, 768
  capture = require("./capture") @, "interact-tangle"

  @then ->
    @execute_cell @append_cell """
        import time
        from math import (sin, cos, tan)

        from IPython.display import display
        from IPython.html.widgets import interact

        from ipytangle import tangle
      """,
      "code"

  @wait_for_idle()

  @then ->
    @execute_cell @append_cell """
        @interact
        def interactor(fn=dict(sin=sin, cos=cos, tan=tan), x=(0, 360)):
            print(fn(x))
      """,
      "code"

  @wait_for_idle()

  @then ->
    cells.md = @append_cell """
        # The [`fn_label`](#:fn_label) function
        The [`fn_label`](#:) of [`x`](#:x) is... some number.
      """,
      "markdown"

  @then ->
    @evaluate (idx) ->
        IPython.notebook.get_cell(idx).render()
      , idx: cells.md

  @then ->
    @execute_cell @append_cell """
        trig_talk = tangle(interactor)
        display(trig_talk)
        trig_talk.x = 42
      """,
      "code"

  @wait_for_idle()

  capture "set-tangle"

  @then ->
    @test.assertSelectorHasText ".widget-readout", "42",
      "...changing tangle changes interact"

  @then ->
    @execute_cell @append_cell """
        interactor.widget.children[1].value = 213
      """,
      "code"

  @wait_for_idle()

  capture "set-interact"

  @then ->
    @test.assertSelectorHasText ".tangle_variable code", "213",
      "...changing interact changes tangle"
