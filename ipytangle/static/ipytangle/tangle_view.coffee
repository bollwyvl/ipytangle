define [
  "underscore"
  "jquery"
  "./lib/d3/d3.js"
  "./lib/rangy/rangy-core.js"
  "widgets/js/widget"
  "base/js/events"
  "base/js/namespace"
], (_, $, d3, rangy, widget, events, IPython) ->
  $win = $ window

  TangleView: class TangleView extends widget.WidgetView
    EVT:
      MD: "rendered.MarkdownCell"

    RE_INTERPOLATE: /\{\{(.+?)\}\}/g

    render: ->
      @templates = {}
      events.on @EVT.MD, @onMarkdown
      super

    remove: ->
      events.off @EVT.MD, @onMarkdown
      super

    nodeToConfig: (el) ->
      """
      implements the ipytangle URL minilanguage
      - `some_namespace:some_variable`
      - `:if:some_variable`
      #:endif
      #:some_variable
      """
      [namespace, expression] = el.attr("href")[1..].split ":"

      template = _.template el.text(), null, interpolate: @RE_INTERPOLATE

      switch expression
        when "if", "endif"
          config =
            type: expression
            template: template
        else
          config =
            type: "variable"
            variable: expression
            template: template
      config or {}

    withType: (selection, _type, handler) ->
      selection.filter ({type}) -> type == _type
        .call handler

    onMarkdown: (evt, {cell}) =>
      view = @

      # transform new elements
      found = d3.select cell.element[0]
        .selectAll "a[href^='#']:not(.tangle)"
        .each ->
          it = d3.select @
          it.datum view.nodeToConfig it
        .classed tangle: 1

      @withType found, "variable", @initVariable
      @withType found, "if", @initIf
      @withType found, "endif", @initEndIf

      tangles = d3.select cell.element[0]
        .selectAll ".tangle"

      @withType found, "variable", @updateVariable
      @withType found, "if", @updateIf
      @withType found, "endif", @updateEndIf

    initEndIf: (field) =>
      field.classed tangle_endif: 1

    updateEndIf: (field) =>
    updateIf: (field) =>

    initIf: (field) =>
      view = @

      field.classed tangle_if: 1
        .text ""
        .each ({template}) ->
          el = d3.select @
          view.listenTo view.model, "change", ->
            show = "true" == template view.model.attributes

            range = rangy.createRange()
            range.setStart el.node()
            # TODO: this is really wrong... probably need a stack?
            range.setEnd d3.select(".tangle_endif").node()

            nodes = d3.selectAll range.getNodes()

            nodes.filter -> @nodeType == 3
              .each ->
                $ @
                  .wrap "<span></span>"

            nodes.filter -> @nodeType != 3
              .classed hide: not show

    updateVariable: (field) =>
      attributes = @model.attributes
      field
        .text ({template}) -> template attributes

    initVariable: (field) =>
      view = @

      drag = d3.behavior.drag()
        .on "drag", ({variable}) =>
          @model.set variable, d3.event.dx + @model.get variable
          @touch()

      field
        .classed tangle_variable: 1
        .attr
            title: "drag"
          .style
            cursor: "ew-resize"
            "text-decoration": "none"
            "border-bottom": "dotted 1px blue"
          .each @tooltip
          .call drag
          .each ({variable, template}) ->
            el = d3.select @
            view.listenTo view.model, "change:#{variable}", ->
              el.text template view.model.attributes


    tooltip: -> $(@).tooltip placement: "bottom", container: "body"
