lib = (path)-> "/nbextensions/ipytangle/lib/#{path}"

require.config
  paths:
    d3: lib "d3/d3"
    math: lib "mathjs/dist/math.min"
    numeral: lib "numeral/min/numeral.min"
    rangy: lib "rangy/rangy-core"

define [
  "underscore"
  "jquery"
  "backbone"
  "moment"
  "d3"
  "math"
  "numeral"
  "rangy"

  "widgets/js/widget"
  "base/js/events"
  "base/js/namespace"

  "./tangle_if.js"
  "./tangle_output.js"
  "./tangle_variable.js"
], (
  _, $, Backbone, moment, d3, math, numeral, rangy,
  widget, events, IPython,
  tangleIf, tangleOutput, tangleVariable
) ->
  "use strict"
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


    register: (urlFrag, {update, init}) =>
      if not @_tangle_handlers
        @_tangle_handlers = {}

      @_tangle_handlers[urlFrag] = {update, init}
      @

    render: ->
      super
      @_modelChange = {}
      view = @
      @templates = {}

      plugin.call @, @ for plugin in [
        tangleIf
        tangleOutput
        tangleVariable
      ]

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

      for frag, {update, init} of @_tangle_handlers
        if init
          @withType found, frag, init

      tangles = d3.select cell.element[0]
        .selectAll ".tangle"

      for frag, {update, init} of @_tangle_handlers
        if update
          @withType tangles, frag, update

      @

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



    tooltip: -> $(@).tooltip placement: "bottom", container: "body"
