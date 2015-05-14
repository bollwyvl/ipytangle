define(
[
  "underscore",
  "widgets/js/widget",
  "base/js/events"
],
function(_, widget, events){
  console.log("TangleView loaded");

  var EVT = {
    MD: "rendered.MarkdownCell"
  };

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
    onMarkdown: function(evt, data){
      var view = this;
      data.cell.element
        .find("a[href^=#]")
        .each(function(){
          var key = $(this).attr("href").slice(1);
          if(!(key in view.model.attributes)){
            return;
          }
          view.bindInput(key, $(this));
        });
    },
    onModelChange: function(){
      // console.log(this.model.changed);
    },
    bindInput: function(key, input){
      var view = this,
        tmpl = _.template(input.text(), null, {interpolate: /\{\{(.+?)\}\}/g}),
        tngl = $("<button/>", {
          title: "drag",
          "class": "btn btn-link"
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
          view.model.set(key, view.model.get(key) + delta);
          view.touch();
        };

      tngl.on("mousedown", startDrag);

      // model -> UI
      view.listenTo(view.model, "change:" + key, function(){
        tngl.text(tmpl(view.model.attributes));
      });

      input.replaceWith(tngl);
    }
  });

  return {
    TangleView: TangleView
  };
});
