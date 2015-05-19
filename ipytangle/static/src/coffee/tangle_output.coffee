define [], ->
  (view)->
    @register "output",
      parse: (expression, el, extras) =>
        if expression is ""
          return type: "output"

      init: (field) =>
        field.classed tangle_output: 1
          .style
            "text-decoration": "none"
            color: "black"

      update: (field) =>
        field.each (d) => d.template @context()
          .each (d) ->
            el = d3.select d
            view.listenTo view.model, "change", ->
              d.template view.context()
