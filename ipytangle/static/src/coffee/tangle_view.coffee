define [
  "underscore"
  "jquery"
  "backbone"
  "moment"
  "../lib/d3/d3.js"
  "../lib/mathjs/dist/math.min.js"
  "../lib/numeral/min/numeral.min.js"
  "../lib/rangy/rangy-core.js"
  "widgets/js/widget"
  "base/js/events"
  "base/js/namespace"
], (
  _, $, Backbone, moment, d3, math, numeral, rangy, widget, events, IPython
) ->
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

    render: ->
      super
      @_modelChange = {}
      view = @
      @templates = {}

      @_env =
        moment: moment
        math: math
        numeral: numeral
        $: (x) -> numeral(x).format "$0.0a"
        floor: (x) -> Math.floor x
        ceil: (x) -> Math.ceil x

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

      @body = @d3.append "div"
        .classed "panel-body": 1
        .append "div"
        .classed row: 1

      events.on @EVT.MD, @onMarkdown
      @update()

      for cell in IPython.notebook.get_cells()
        if cell.cell_type == "markdown" and cell.rendered
          cell.unrender()
          cell.execute()

    update: ->
      super
      view = @

      now = new Date()
      changed = @model.changed
      @_modelChange[key] = now for key of @model.changed

      expanded = @model.get "_expanded"

      @d3.classed
        docked: expanded

      rows = d3.entries @model.attributes
        .filter (attr) -> attr.key[0] != "_"
        .filter (attr) ->
          attr.key not in view.model.attributes._tangle_upstream_traits
      rows.sort (a, b) =>
        d3.descending(@_modelChange[a.key], @_modelChange[b.key]) or d3.ascending a.key, b.key


      row = @body.data [rows]
        .order()
        .classed
          hide: not expanded
        .selectAll ".variable"
        .data (data) -> data
        .call ->
          init = @enter().append "div"
            .classed
              variable: 1
          init.append "h6"
          init.append "input"
            .classed
              "form-control": 1
            .on "input", ({key, value}) ->
              view.model.set key, d3.select(@).property "value"
              view.touch()

      row.select "h6"
        .text ({key}) -> key

      row.select "input"
        .property value: ({value}) -> value

      row.filter (d) -> d.key of changed
        .select "input"
        .style
          "background-color": "yellow"
        .transition()
        .style
          "background-color": "white"

      @

    remove: ->
      events.off @EVT.MD, @onMarkdown
      super

    tmplUpdateClasses: ({up, down}) ->
      "tangle-unupdated": not (up or down)
      "tangle-updated": up
      "tangle-downdated": down

    template: (el, config) =>
      _update = @tmplUpdateClasses

      if config.type in ["if", "elsif"]
        return _.template "<%= #{el.select("code").text()} %>"
      else if config.type in ["endif", "else"]
        return ->

      codes = el.selectAll "code"
        .each ->
          src = @textContent
          d3.select @
            .datum ->
              fn: new Function "obj", """
                  with(obj){
                    return (#{src});
                  }
                """

      (attributes) ->
        codes
          .each (d) ->
            d._old = @textContent
            d._new = "#{d.fn attributes}"
          .text (d) -> d._new

        updated = codes.filter (d) -> d._old < d._new
          .classed _update up: 1

        downdated = codes.filter (d) -> d._old > d._new
          .classed _update down: 1

        _.delay =>
            updated.classed _update {}
            downdated.classed _update {}
          ,
          300

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
        when "if", "endif", "else", "elsif"
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
      @withType found, "if", @initClassed "tangle_if"
      @withType found, "else", @initClassed "tangle_else"
      @withType found, "elsif", @initClassed "tangle_elsif"
      @withType found, "endif", @initClassed "tangle_endif"

      tangles = d3.select cell.element[0]
        .selectAll ".tangle"

      @withType tangles, "output", @updateOutput
      @withType tangles, "variable", @updateVariable
      @withType tangles, "if", @updateIf

      @

    initOutput: (field) =>
      view = @

      field.classed tangle_output: 1
        .style
          "text-decoration": "none"
          color: "black"

    updateOutput: (field) =>
      view = @
      field.each (d) => d.template @context()
        .each (d) ->
          el = d3.select d
          view.listenTo view.model, "change", ->
            d.template view.context()

    initClassed: (cls) ->
      (field) ->
        field.classed cls, 1
          .style display: "none"

    stackMatch: (elFor, pushers, poppers) =>
      """
      Given a grammar of stack poppers and pushers

      if +
      else -+
      elsif -+
      endif -

      and the current element, determine the next element
      """
      stack = []
      found = null

      sel = []
        .concat pushers
        .concat poppers
        .map (sel) -> ".#{sel}"
        .join ", "

      d3.selectAll sel
        .each ->
          return if found
          el = d3.select @

          for popper in poppers
            continue if found
            if el.classed popper
              popped = stack.pop()

              if popped == elFor.node()
                found = @

          for pusher in pushers
            if el.classed pusher
              stack.push @

      d3.select found

    context: =>
      context = _.extend {},
        @_env
        @model.attributes

      context

    toggleRange: (first, last, show) ->
      range = rangy.createRange()
      # this is easy
      range.setStart first.node()
      range.setEnd last.node()

      rawNodes = range.getNodes()

      nodes = d3.selectAll rawNodes

      nodes.filter -> @nodeType == 3
        .each ->
          if @parentNode not in rawNodes
            $ @
              .wrap "<span></span>"

      nodes.filter -> @nodeType != 3
        .classed hide: not show


    updateIf: (field) =>
      view = @

      field.each (d) ->
        el = d3.select @
        change = ->
          pushers = ["tangle_if", "tangle_else", "tangle_elsif"]
          poppers = ["tangle_endif", "tangle_else", "tangle_elsif"]
          current = el
          show = false

          while not current.classed "tangle_endif"
            if current == el
              show = "true" == d.template view.context()
            else if current.classed "tangle_else"
              show = not show

            prev = current
            current = view.stackMatch prev, pushers, poppers

            if current.classed "tangle_endif"
              break

            view.toggleRange prev, current, show


        view.listenTo view.model, "change", change
        # TODOD: fix this
        change()
        change()

    updateVariable: (field) =>
      view = @

      field
        .each ({template}) -> template view.context()
        .each ({variable, template}) ->
          el = d3.select @
          view.listenTo view.model, "change:#{variable}", ->
            template view.context()

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
