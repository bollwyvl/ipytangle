define [
  "d3"
], (d3) ->
  (view) ->
    @register "variable",
      parse: (expression, el, extra) =>
        if expression is ""
          return

        config =
          type: "variable"
          variable: expression

        values = "#{expression}_options"
        if values of @model.attributes
          config.options = => @model.get values

        config

      update: (field) =>
        field
          .each ({template}) -> template view.context()
          .each ({variable, template}) ->
            el = d3.select @
            view.listenTo view.model, "change:#{variable}", ->
              template view.context()

      init: (field) =>
        field
          .classed tangle_variable: 1
          .style
            "text-decoration": "none"
            "border-bottom": "dotted 1px blue"

        field.filter ({options, variable}) ->
            not options and typeof view.model.attributes[variable] == "number"
          .call @initVariableNumeric

        field.filter ({options}) -> options
          .call @initVariableoptions

        field
          .each @tooltip


    @initVariableoptions = (field) =>
      field
        .attr
          title: "click"
        .on "click", (d) =>
          old = @model.get d.variable
          options = d.options()
          old_idx = options.indexOf old
          @model.set d.variable, options[(old_idx + 1) %% (options.length)]
          @touch()


    @initVariableNumeric = (field) =>
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
