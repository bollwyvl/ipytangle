define [
  "underscore"
  "jquery"
  "../lib/d3/d3.js"
  "backbone"
  "../lib/rangy/rangy-core.js"
  "widgets/js/widget"
  "base/js/events"
  "base/js/namespace"
], (_, $, d3, Backbone, rangy, widget, events, IPython) ->
  $win = $ window

  d3.select "head"
    .selectAll "#tangle-styles"
    .data [1]
    .enter()
    .append "link"
    .attr
      id: "tangle-styles"
      href: "/nbextensions/ipytangle/css/tangle.css"
      rel: "stylesheet"

  TangleView: class TangleView extends widget.WidgetView
    EVT:
      MD: "rendered.MarkdownCell"

    RE_INTERPOLATE: /`(.+?)`/g

    render: ->
      super
      view = @
      @templates = {}
      @d3 = d3.select @el
        .classed
          "widget-tangle": 1
          panel: 1
          "panel-info": 1
        .style
          width: "100%"

      @heading = @d3.append "div"
        .classed "panel-heading": 1

      @title = @heading.append "h3"
        .classed "panel-title": 1

      @title
        .append "span"
        .text "Tangle"

      @title.append "button"
        .classed
          "pull-right": 1
          btn: 1
          "btn-link": 1
        .style
          "margin-top": 0
          "padding": 0
          height: "24px"
        .on "click", =>
          @model.set "_expanded", not @model.get "_expanded"
          @update()
        .append "i"
        .classed fa: 1, "fa-fw": 1, "fa-ellipsis-h": 1, "fa-2x": 1

      @table = @d3.append "table"
        .classed table: 1, "table-hover": 1
      @table.append "thead"
      @table.append "tbody"

      events.on @EVT.MD, @onMarkdown
      @update()

      @onMarkdown null, cell: cell for cell in IPython.notebook.get_cells()

    update: ->
      super
      view = @

      expanded = @model.get "_expanded"

      @d3.classed
        docked: expanded

      rows = d3.entries @model.attributes
        .filter (attr) -> attr.key[0] != "_"
        .filter (attr) ->
          attr.key not in view.model.attributes._tangle_upstream_traits
      rows.sort (a, b) -> d3.ascending a.key, b.key

      row = @table.data [rows]
        .classed
          hide: not expanded

        .call ->
          init = @enter()

        .select "tbody"
        .selectAll "tr"
        .data (data) -> data
        .call ->
          init = @enter().append "tr"
          init.append "th"
          init.append "td"
            .style
              width: "100%"
            .append "input"
            .classed
              "form-control": 1
            .on "input", ({key, value}) ->
              view.model.set key, d3.select(@).property "value"
              view.touch()

      row.select "th"
        .text ({key}) -> key

      row.select "input"
        .property value: ({value}) -> value

      @

    remove: ->
      events.off @EVT.MD, @onMarkdown
      super

    template: (el, config) =>
      codes = el.selectAll "code"
        .each ->
          src = @textContent
          d3.select @
            .datum -> new Function "obj", "with(obj){return (#{src});}"

      (attributes) ->
        codes.text (fn) -> fn attributes

    nodeToConfig: (el) ->
      """
      implements the ipytangle URL minilanguage
      - `:` a pure output view
      - `<undecided_namespace>:some_variable`
      - `:if` and `:endif`
      """
      [namespace, expression] = el.attr("href")[1..].split ":"

      config = {}

      switch expression
        when ""
          config =
            type: "output"
        when "if", "endif"
          config =
            type: expression
        else
          config =
            type: "variable"
            variable: expression

          values = "_#{expression}_choices"
          if values of @model.attributes
            config.choices = => @model.get values

      config.template = @template el, config

      config or {}

    withType: (selection, _type, handler) ->
      selection.filter ({type}) -> type == _type
        .call handler

    onMarkdown: (evt, {cell}) =>
      view = @

      # transform new elements
      found = d3.select cell.element[0]
        .selectAll "a[href^='#']:not(.tangle):not(.anchor-link)"
        .each ->
          it = d3.select @
          it.datum view.nodeToConfig it
        .classed tangle: 1

      @withType found, "output", @initOutput
      @withType found, "variable", @initVariable
      @withType found, "if", @initIf
      @withType found, "endif", @initEndIf

      tangles = d3.select cell.element[0]
        .selectAll ".tangle"

      @withType tangles, "output", @updateOutput
      @withType tangles, "variable", @updateVariable
      @withType tangles, "if", @updateIf
      @withType tangles, "endif", @updateEndIf

    initOutput: (field) =>
      view = @

      field.classed tangle_output: 1
        .style
          "text-decoration": "none"
          color: "black"

    updateOutput: (field) =>
      view = @
      field.each (d) => d.template @model.attributes
        .each (d) ->
          view.listenTo view.model, "change", ->
            d.template view.model.attributes


    initEndIf: (field) =>
      field.classed tangle_endif: 1
        .style display: "none"

    updateEndIf: (field) =>

    getStackMatch: (elFor, pushSel, popSel) =>
      stack = []
      found = null
      d3.selectAll ".#{pushSel}, .#{popSel}"
        .each ->
          return if found
          el = d3.select @
          if el.classed pushSel
            stack.push @
          else
            popped = stack.pop()
            if popped == elFor
              found = @
      found

    initIf: (field) =>
      view = @

      field.classed tangle_if: 1
        .style display: "none"

    updateIf: (field) =>
      view = @

      field.each (d) ->
        el = d3.select @
        view.listenTo view.model, "change", ->
          show = "true" == d.template view.model.attributes

          range = rangy.createRange()
          # this is easy
          range.setStart el.node()

          d.end = d.end or view.getStackMatch el.node(),
            "tangle_if",
            "tangle_endif"

          range.setEnd d.end

          nodes = d3.selectAll range.getNodes()

          nodes.filter -> @nodeType == 3
            .each ->
              $ @
                .wrap "<span></span>"

          nodes.filter -> @nodeType != 3
            .classed hide: not show

    updateVariable: (field) =>
      view = @

      field
        .each ({template}) -> template view.model.attributes
        .each ({variable, template}) ->
          el = d3.select @
          view.listenTo view.model, "change:#{variable}", ->
            template view.model.attributes

    initVariable: (field) =>
      view = @

      field
        .classed tangle_variable: 1
        .style
          "text-decoration": "none"
          "border-bottom": "dotted 1px blue"

      field.filter ({choices, variable}) ->
          not choices and typeof view.model.attributes[variable] == "number"
        .call @initVariableNumeric

      field.filter ({choices}) -> choices
        .call @initVariableChoices

      field
        .each @tooltip

    initVariableChoices: (field) =>
      field
        .attr
          title: "click"
        .on "click", (d) =>
          old = @model.get d.variable
          choices = d.choices()
          old_idx = choices.indexOf old
          @model.set d.variable, choices[(old_idx + 1) %% (choices.length)]
          @touch()

    initVariableNumeric: (field) =>
      _touch = _.debounce => @touch()

      drag = d3.behavior.drag()
        .on "drag", (d) =>
          old = @model.get d.variable
          @model.set d.variable, d3.event.dx + old
          _touch()

      field
        .attr
          title: "drag"
        .style
          cursor: "ew-resize"
        .call drag


    tooltip: -> $(@).tooltip placement: "bottom", container: "body"
