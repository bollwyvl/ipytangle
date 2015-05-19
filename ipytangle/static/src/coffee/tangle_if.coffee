define [], ->
  (view)->
    @register "if",
      init: (field) =>
        field.classed "tangle_if", 1
          .style display: "none"

      update: (field) =>
        field.each (d) ->
          el = d3.select @
          change = ->
            pushers = ["tangle_if", "tangle_else", "tangle_elsif"]
            poppers = ["tangle_endif", "tangle_else", "tangle_elsif"]
            current = el
            # only show the first hit
            shown = false
            show = false

            while not current.classed "tangle_endif"
              if current == el
                show = "true" == d.template view.context()
              else if current.classed "tangle_elsif"
                show = "true" == current.datum().template view.context()
              else if current.classed "tangle_else"
                show = not shown

              prev = current
              current = view.stackMatch prev, pushers, poppers

              view.toggleRange prev, current, if shown then false else show
              shown = shown or show


          view.listenTo view.model, "change", change
          # TODOD: fix this
          change()
          change()

    @register "elsif",
      init: (field) =>
        field.classed "tangle_elsif", 1
          .style display: "none"


    @register "else",
      init: (field) =>
        field.classed "tangle_else", 1
          .style display: "none"

    @register "endif",
      init: (field) =>
        field.classed "tangle_endif", 1
          .style display: "none"
