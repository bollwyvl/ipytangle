define [
  "d3"
], (d3) ->
  (view) ->
    @initVariableChoices = (field) =>
      field
        .attr
          title: "click"
        .on "click", (d) =>
          old = @model.get d.variable
          choices = d.choices()
          old_idx = choices.indexOf old
          @model.set d.variable, choices[(old_idx + 1) %% (choices.length)]
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

    @register "variable",
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

        field.filter ({choices, variable}) ->
            not choices and typeof view.model.attributes[variable] == "number"
          .call @initVariableNumeric

        field.filter ({choices}) -> choices
          .call @initVariableChoices

        field
          .each @tooltip
