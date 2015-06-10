casper.notebook_test ->
  cells = {}

  @viewport 1024, 768
  capture = require("./capture") @, "error"

  @then ->
    @execute_cell @append_cell """
        import time
        from IPython.display import display
        from ipytangle import tangle
      """,
      "code"

  @wait_for_idle()

  @then ->
    @execute_cell @append_cell """
        jar = tangle(cookies=3, calories=(150, lambda cookies: cookies * 50))
      """,
      "code"

  @wait_for_idle()

  @then ->
    @execute_cell @append_cell """
        display(jar)
      """,
      "code"

  @wait_for_idle()

  @then ->
    cells.md = @append_cell """
        Let them eat [`cake`](#:).
      """,
      "markdown"

  @wait_for_idle()

  @then ->
    @evaluate (idx) ->
        IPython.notebook.get_cell(idx).render()
      , idx: cells.md

  @wait_for_idle()

  @then ->
    @test.assertExists "code.error",
      "...a missing key shows a visual error"

  @then ->
    @wait 1000, ->
      capture "missing"
