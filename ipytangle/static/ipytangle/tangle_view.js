define(
[
  "underscore",
  "widgets/js/widget",
  "base/js/events",
  "base/js/namespace"
],
function(_, widget, events, IPython){
  console.log("TangleView loaded");

  var EVT = {
    MD: "rendered.MarkdownCell"
  };

  var RE_INTERPOLATE = /\{\{(.+?)\}\}/g;

  var $win = $(window);

  var TangleView = widget.WidgetView.extend({
    initialize: function(){
      _.bindAll(this, "onMarkdown", "onModelChange", "bindInput");
      this.listenTo(this.model, "change", this.onModelChange);
      return TangleView.__super__.initialize.apply(this, arguments);
    },
    render: function(){
      events.on(EVT.MD, this.onMarkdown);
      return TangleView.__super__.render.apply(this, arguments);
    },
    remove: function(){
      events.off(EVT.MD, this.onMarkdown);
      return TangleView.__super__.remove.apply(this, arguments);
    },
    hashToConfig: function(hash){
      /*
        turn a URL hash into a config object for tangle
        :<variable>
        :<variable>:<control>

        the simplest case (a global tangle) has the shortcut
      */
      var bits = hash.slice(1).split(":"),
        config = {};

      switch(bits.length){
        case 2:
          switch(bits[0]){
              case "": config.variable = bits[1]; break;
          }
          break;
      }

      return config;
    },
    onMarkdown: function(evt, data){
      var view = this;
      data.cell.element
        .find("a[href^=#]")
        .each(function(){
          var cfg = view.hashToConfig($(this).attr("href"));

          if(!cfg || !(cfg.variable in view.model.attributes)){
            return;
          }

          view.bindInput(cfg, $(this));
        });
    },
    onModelChange: function(){
      // console.log(this.model.changed);
    },
    bindInput: function(cfg, input){
      var view = this,
        tmpl = _.template(input.text(), null, {interpolate: RE_INTERPOLATE}),
        tngl = $("<button/>", {
          title: "drag",
          "class": "btn btn-link tangle"
        })
        .text(tmpl(view.model.attributes))
        .css({
          cursor: "ew-resize",
          "text-decoration": "none",
          "border-bottom": "dotted 1px blue",
          "user-select": "none",
          "padding": 0
        })
        .tooltip({
          placement: "bottom",
          container: "body"
        });

      // UI -> model
      var _x,
        startDrag = function(evt){
          _x = evt.screenX;
          $win.on("mousemove", drag).on("mouseup", endDrag);
        },
        endDrag = function(){
          _x = null;
          $win.off("mousemove", drag).off("mouseup", endDrag);
        },
        drag = function(evt){
          var delta = evt.screenX - _x;
          _x = evt.screenX;
          view.model.set(cfg.variable, view.model.get(cfg.variable) + delta);
          view.touch();
        };

      tngl.on("mousedown", startDrag);

      // model -> UI
      view.listenTo(view.model, "change:" + cfg.variable, function(){
        tngl.text(tmpl(view.model.attributes));
      });

      input.replaceWith(tngl);
    }
  });

  return {
    TangleView: TangleView
  };
});
