define [
  "underscore"
  "widgets/js/widget"
  "base/js/events"
  "base/js/namespace"
], (_, widget, events, IPython) ->
  $win = $ window

  class TangleView extends widget.Widget
    EVT:
      MD: "rendered.MarkdownCell"

    RE_INTERPOLATE: /\{\{(.+?)\}\}/g

    render: ->
      events.on @EVT.MD, @onMarkdown
      super

    remove: ->
      events.off EVT.MD, @onMarkdown

    onMarkdown: (evt, {cell})=>
      view = @
      cell.element
        .find "a[href^=#]"
        .each (idx, el) ->
          cfg = view.hashToConfig $(el).attr "href"

          if cfg and cfg.variable in view.model.attributes
            return

          view.bindInput cfg, $ el

    bindInput: (cfg, el) =>
      view = @
      tmpl = _.template el.text(), null,
        interpolate: @RE_INTERPOLATE

      tngl = $ "<button/>",
          title: "drag"
          class: "btn btn-link tangle"
        .text tmpl @model.attributes
        .css
          cursor: "ew-resize"
          "text-decoration": "none"
          "border-bottom": "dotted 1px blue"
          "user-select": "none"
          padding: 0
        .tooltip placement: "bottom", container; "body"

      _x = null

      drag = ({screenX}) =>
        delta = screenX - _x
        _x = screenX
        @model.set cfg.variable,
          @model.get(cfg.variable) + delta
        @touch()

      startDrag = ({screenX})->
        _x = _screenX
        $win.on "mousemove", drag
          .on "mouseup", endDrag

      endDrag = ->
        _x = null
        $win.off "mousemove", drag
          .off "mouseup", endDrag

      tngle.on "mousedown", startDrag

      @listenTo @model, "change:#{cfg.variable}", =>
        tngl.text tmpl @model.attributes

      el.replaceWith tngl

    hashToConfig: (hash) ->
      bits = hash[1:].split ":"
      config = {}

      switch bits.length
        when 2
          switch bits[0]
            when ""
              config.variable = bits[1]

      config

  TangleView: TangleView
