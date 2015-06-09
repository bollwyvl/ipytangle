lib = (path) -> "/nbextensions/ipytangle/lib/#{path}"

require.config
  paths:
    d3: lib "d3/d3"

define [
  "d3"
  "jquery"
  "notebook/js/celltoolbar"
  "base/js/namespace"
],
(d3, $, {CellToolbar}, {keyboard_manager}) ->
  ifCell = (div, cell) ->
    div = d3.select div[0]
      .style
        height: null
        padding: 0

    val = (val) ->
      if not arguments.length
        cell.metadata.tangle?.showIf
      else
        if not md = cell.metadata.tangle
          md = cell.metadata.tangle = {}
        md.showIf = val

    group = div.append "div"
      .classed "form-inline": 1
      .append "div"
      .classed
        "tangle-cell-showif": 1
        "form-group": 1

    group.append "label"
      .text "Show if"
    input = group.append "input"
      .classed
        "form-control": 1
        "input-xs": 1
      .style
        height: "20px"
        width: "300px"
      .attr
        placeholder: "always"
        value: val()
      .on "input", -> val @value

    keyboard_manager.register_events $ input.node()

  register: (notebook) ->
    CellToolbar.register_callback 'tangle.if', ifCell
    CellToolbar.register_preset 'Tangle', ["tangle.if"], notebook
