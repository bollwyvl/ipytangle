casper.notebook_test ->
  cells = {}

  @viewport 1024, 2000
  capture = require("./capture") @, "tangle-interact"

  @then ->
    @execute_cell @append_cell """
        import time
        import math

        from IPython.display import display
        from IPython.html.widgets import interact

        from ipytangle import tangle
      """,
      "code"

  @then ->
    cells.md = @append_cell """
        # The [`fn`](#:fn) function
        The [`fn`](#:) of [`x`](#:x) is [`fn_of_x`](#:).
      """,
      "markdown"

  @then ->
    @evaluate (idx) ->
        IPython.notebook.get_cell(idx).render()
      , idx: cells.md

  @then ->
    @execute_cell @append_cell """
        trig_talk = tangle(
            fn=["sin", "cos", "tan"],
            x=1,
            fn_of_x=(0.0, lambda fn, x: getattr(math, fn)(x))
        )
        display(trig_talk)
      """,
      "code"

  @wait_for_idle()

  @then ->
    @execute_cell @append_cell """
        @interact
        def interactor(t=trig_talk, y=1.0):
            print(t.fn_of_x + y)
      """,
      "code"

  @wait_for_idle()

  @then ->
    @execute_cell cells.set_x = @append_cell """
        trig_talk.x = 2
      """,
      "code"

  @then ->
    @evaluate (idx) ->
        IPython.notebook.select(idx)
      , idx: cells.set_x

  @wait_for_idle()

  capture "set-x"

  @then ->
    @test.assertSelectorHasText ".selected .output_stdout",
      "1.9092974268256817\n",
      "...changing tangle changes interact"
