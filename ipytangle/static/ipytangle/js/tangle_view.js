// Generated by CoffeeScript 1.9.2
(function() {
  var lib,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    slice = [].slice;

  lib = function(path) {
    return "/nbextensions/ipytangle/lib/" + path;
  };

  require.config({
    paths: {
      d3: lib("d3/d3"),
      math: lib("mathjs/dist/math.min"),
      numeral: lib("numeral/min/numeral.min"),
      rangy: lib("rangy/rangy-core")
    }
  });

  define(["underscore", "jquery", "backbone", "moment", "d3", "math", "numeral", "rangy", "widgets/js/widget", "base/js/events", "base/js/namespace", "./tangle_if.js", "./tangle_output.js", "./tangle_variable.js"], function(_, $, Backbone, moment, d3, math, numeral, rangy, widget, events, IPython, tangleIf, tangleOutput, tangleVariable) {
    "use strict";
    var $win, TangleView;
    $win = $(window);
    d3.select("head").selectAll("#tangle-styles").data([1]).enter().append("link").attr({
      id: "tangle-styles",
      href: "/nbextensions/ipytangle/css/tangle.css",
      rel: "stylesheet"
    });
    return {
      TangleView: TangleView = (function(superClass) {
        extend(TangleView, superClass);

        function TangleView() {
          this.context = bind(this.context, this);
          this.stackMatch = bind(this.stackMatch, this);
          this.onMarkdown = bind(this.onMarkdown, this);
          this.template = bind(this.template, this);
          this.register = bind(this.register, this);
          return TangleView.__super__.constructor.apply(this, arguments);
        }

        TangleView.prototype.EVT = {
          MD: "rendered.MarkdownCell"
        };

        TangleView.prototype.register = function(urlFrag, opt) {
          if (urlFrag == null) {
            urlFrag = null;
          }
          if (opt == null) {
            opt = null;
          }
          if (!this._tangle_handlers) {
            this._tangle_handlers = {};
          }
          if (urlFrag === null) {
            return this._tangle_handlers;
          }
          if (opt === null) {
            return this._tangle_handlers[urlFrag];
          }
          this._tangle_handlers[urlFrag] = opt;
          return this;
        };

        TangleView.prototype.render = function() {
          var cell, i, j, len, len1, plugin, ref, ref1, results, view;
          TangleView.__super__.render.apply(this, arguments);
          this._modelChange = {};
          view = this;
          this.templates = {};
          ref = [tangleIf, tangleOutput, tangleVariable];
          for (i = 0, len = ref.length; i < len; i++) {
            plugin = ref[i];
            plugin.call(this, this);
          }
          this._env = {
            moment: moment,
            math: math,
            numeral: numeral,
            $: function(x) {
              return numeral(x).format("$0.0a");
            },
            floor: function(x) {
              return Math.floor(x);
            },
            ceil: function(x) {
              return Math.ceil(x);
            }
          };
          this.d3 = d3.select(this.el).classed({
            "widget-tangle": 1,
            panel: 1,
            "panel-info": 1
          }).style({
            width: "100%"
          });
          this.heading = this.d3.append("div").classed({
            "panel-heading": 1
          });
          this.title = this.heading.append("h3").classed({
            "panel-title": 1
          });
          this.title.append("span").text("Tangle");
          this.title.append("button").classed({
            "pull-right": 1,
            btn: 1,
            "btn-link": 1
          }).style({
            "margin-top": 0,
            "padding": 0,
            height: "24px"
          }).on("click", (function(_this) {
            return function() {
              _this.model.set("_expanded", !_this.model.get("_expanded"));
              return _this.update();
            };
          })(this)).append("i").classed({
            fa: 1,
            "fa-fw": 1,
            "fa-ellipsis-h": 1,
            "fa-2x": 1
          });
          this.body = this.d3.append("div").classed({
            "panel-body": 1
          }).append("div").classed({
            row: 1
          });
          events.on(this.EVT.MD, this.onMarkdown);
          this.update();
          ref1 = IPython.notebook.get_cells();
          results = [];
          for (j = 0, len1 = ref1.length; j < len1; j++) {
            cell = ref1[j];
            if (cell.cell_type === "markdown" && cell.rendered) {
              cell.unrender();
              results.push(cell.execute());
            } else {
              results.push(void 0);
            }
          }
          return results;
        };

        TangleView.prototype.update = function() {
          var changed, expanded, key, now, row, rows, view;
          TangleView.__super__.update.apply(this, arguments);
          view = this;
          now = new Date();
          changed = this.model.changed;
          for (key in this.model.changed) {
            this._modelChange[key] = now;
          }
          expanded = this.model.get("_expanded");
          this.d3.classed({
            docked: expanded
          });
          rows = d3.entries(this.model.attributes).filter(function(attr) {
            return attr.key[0] !== "_";
          }).filter(function(attr) {
            var ref;
            return ref = attr.key, indexOf.call(view.model.attributes._tangle_upstream_traits, ref) < 0;
          });
          rows.sort((function(_this) {
            return function(a, b) {
              return d3.descending(_this._modelChange[a.key], _this._modelChange[b.key]) || d3.ascending(a.key, b.key);
            };
          })(this));
          row = this.body.data([rows]).order().classed({
            hide: !expanded
          }).selectAll(".variable").data(function(data) {
            return data;
          }).call(function() {
            var init;
            init = this.enter().append("div").classed({
              variable: 1
            });
            init.append("h6");
            return init.append("input").classed({
              "form-control": 1
            }).on("input", function(arg) {
              var key, value;
              key = arg.key, value = arg.value;
              view.model.set(key, d3.select(this).property("value"));
              return view.touch();
            });
          });
          row.select("h6").text(function(arg) {
            var key;
            key = arg.key;
            return key;
          });
          row.select("input").property({
            value: function(arg) {
              var value;
              value = arg.value;
              return value;
            }
          });
          row.filter(function(d) {
            return d.key in changed;
          }).select("input").style({
            "background-color": "yellow"
          }).transition().style({
            "background-color": "white"
          });
          return this;
        };

        TangleView.prototype.remove = function() {
          events.off(this.EVT.MD, this.onMarkdown);
          return TangleView.__super__.remove.apply(this, arguments);
        };

        TangleView.prototype.tmplUpdateClasses = function(arg) {
          var down, up;
          up = arg.up, down = arg.down;
          return {
            "tangle-unupdated": !(up || down),
            "tangle-updated": up,
            "tangle-downdated": down
          };
        };

        TangleView.prototype.template = function(el) {
          var _update, codes;
          _update = this.tmplUpdateClasses;
          codes = el.selectAll("code").each(function() {
            var src;
            src = this.textContent;
            return d3.select(this).datum(function() {
              return {
                fn: new Function("obj", "with(obj){\n  return (" + src + ");\n}")
              };
            });
          });
          return function(attributes) {
            var downdated, updated;
            codes.each(function(d) {
              var err, it;
              it = d3.select(this);
              d._old = this.textContent;
              try {
                d._new = "" + (d.fn(attributes));
                return it.classed({
                  error: 0
                });
              } catch (_error) {
                err = _error;
                console.error("Tangle error:\n" + err);
                d._new = d._old;
                return it.classed({
                  error: 1
                });
              }
            }).text(function(d) {
              return d._new;
            });
            updated = codes.filter(function(d) {
              return d._old < d._new;
            }).classed(_update({
              up: 1
            }));
            downdated = codes.filter(function(d) {
              return d._old > d._new;
            }).classed(_update({
              down: 1
            }));
            return _.delay((function(_this) {
              return function() {
                updated.classed(_update({}));
                return downdated.classed(_update({}));
              };
            })(this), 300);
          };
        };

        TangleView.prototype.nodeToConfig = function(el) {
          "implements the ipytangle URL minilanguage";
          var config, extra, frag, handler, handlerFrag, namespace, ref, ref1;
          ref = el.attr("href").slice(1).split(":"), namespace = ref[0], frag = ref[1], extra = 3 <= ref.length ? slice.call(ref, 2) : [];
          handler = this.register(frag);
          if (handler) {
            config = typeof handler.parse === "function" ? handler.parse(frag, el, extra) : void 0;
            config = config || {
              type: frag
            };
          } else {
            ref1 = this.register();
            for (handlerFrag in ref1) {
              handler = ref1[handlerFrag];
              config = typeof handler.parse === "function" ? handler.parse(frag, el, extra) : void 0;
              if (config) {
                break;
              }
            }
          }
          if (config.template) {
            config.template = config.template(el);
          } else {
            config.template = this.template(el);
          }
          return config;
        };

        TangleView.prototype.withType = function(selection, _type, handler) {
          return selection.filter(function(arg) {
            var type;
            type = arg.type;
            return type === _type;
          }).call(handler);
        };

        TangleView.prototype.onMarkdown = function(evt, arg) {
          var cell, found, frag, init, ref, ref1, ref2, ref3, tangles, update, view;
          cell = arg.cell;
          view = this;
          found = d3.select(cell.element[0]).selectAll("a[href^='#']:not(.tangle):not(.anchor-link)").each(function() {
            var it;
            it = d3.select(this);
            return it.datum(view.nodeToConfig(it));
          }).classed({
            tangle: 1
          });
          ref = this.register();
          for (frag in ref) {
            ref1 = ref[frag], update = ref1.update, init = ref1.init;
            if (init) {
              this.withType(found, frag, init);
            }
          }
          tangles = d3.select(cell.element[0]).selectAll(".tangle");
          ref2 = this.register();
          for (frag in ref2) {
            ref3 = ref2[frag], update = ref3.update, init = ref3.init;
            if (update) {
              this.withType(tangles, frag, update);
            }
          }
          return this;
        };

        TangleView.prototype.stackMatch = function(elFor, pushers, poppers) {
          "Given a grammar of stack poppers and pushers\n\nif +\nelse -+\nelsif -+\nendif -\n\nand the current element, determine the next element";
          var found, sel, stack;
          stack = [];
          found = null;
          sel = [].concat(pushers).concat(poppers).map(function(sel) {
            return "." + sel;
          }).join(", ");
          d3.selectAll(sel).each(function() {
            var el, i, j, len, len1, popped, popper, pusher, results;
            if (found) {
              return;
            }
            el = d3.select(this);
            for (i = 0, len = poppers.length; i < len; i++) {
              popper = poppers[i];
              if (found) {
                continue;
              }
              if (el.classed(popper)) {
                popped = stack.pop();
                if (popped === elFor.node()) {
                  found = this;
                }
              }
            }
            results = [];
            for (j = 0, len1 = pushers.length; j < len1; j++) {
              pusher = pushers[j];
              if (el.classed(pusher)) {
                results.push(stack.push(this));
              } else {
                results.push(void 0);
              }
            }
            return results;
          });
          return d3.select(found);
        };

        TangleView.prototype.context = function() {
          var context;
          context = _.extend({}, this._env, this.model.attributes);
          return context;
        };

        TangleView.prototype.toggleRange = function(first, last, show) {
          var nodes, range, rawNodes;
          range = rangy.createRange();
          range.setStart(first.node());
          range.setEnd(last.node());
          rawNodes = range.getNodes();
          nodes = d3.selectAll(rawNodes);
          nodes.filter(function() {
            return this.nodeType === 3;
          }).each(function() {
            var ref;
            if (ref = this.parentNode, indexOf.call(rawNodes, ref) < 0) {
              return $(this).wrap("<span></span>");
            }
          });
          return nodes.filter(function() {
            return this.nodeType !== 3;
          }).classed({
            hide: !show
          });
        };

        TangleView.prototype.tooltip = function() {
          return $(this).tooltip({
            placement: "bottom",
            container: "body"
          });
        };

        return TangleView;

      })(widget.WidgetView)
    };
  });

}).call(this);
