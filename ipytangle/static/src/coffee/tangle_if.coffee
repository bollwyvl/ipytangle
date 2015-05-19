define [
  "underscore"
], (_)->
  (view)->
    classedHidden = (cls)->
      (field) ->
        field.classed "tangle_#{cls}", 1
          .style display: "none"

    template = (el) -> _.template "<%= #{el.select("code").text()} %>"

    @register "if",
      init: classedHidden "if"

      parse: (frag, el, extra) =>
        if frag is "if"
          type: "if"
          template: template

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
      init: classedHidden "elsif"

      parse: (frag, el, extra) =>
        if frag is "elsif"
          type: "elsif"
          template: template

    for key in ["else", "endif"]
      @register key,
        init: classedHidden key
        parse: (frag, el, extra) =>
          if frag is key
            type: key
            template: ->
