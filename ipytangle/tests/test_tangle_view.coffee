casper.notebook_test ->
  cells = {}

  @viewport 1024, 768
  capture = require("./capture") @, "cookies"

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
    @test.assertExists "link[href*='tangle.css']",
      "...style loaded"

  @then ->
    cells.md = @append_cell """
        When you eat [`cookies` cookies](#:cookies), you consume
        [`calories` calories](#:).
      """,
      "markdown"

  capture "render"

  @then ->
    @evaluate (idx) ->
        IPython.notebook.get_cell(idx).render()
      , idx: cells.md

  capture "render2"

  @then ->
    @test.assertSelectorHasText ".tangle_variable code", "3",
      "...value is initialized"

  @then ->
    @execute_cell @append_cell """
        jar.cookies = 1
        time.sleep(1)
        print(jar.cookies)
      """,
      "code"

  @wait_for_idle()

  @then ->
    @test.assertSelectorHasText ".tangle_variable code", "1",
      "...value changed"

  @then ->
    @wait 1000, ->
      capture "change"
