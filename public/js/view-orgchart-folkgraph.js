
BehaviorManager.register("adjustCanvas", function() {
  var dims = document.viewport.getDimensions();
  var offset = $("container").cumulativeOffset();
  var width = dims.width - offset.left, height = dims.height - offset.top;
  var style = {width: width + "px", height: height + "px"};
  console.log($H(style).inspect());
  var container = $("container");
  var viz = container.retrieve("viz");
  viz && viz.canvas.resize(width, height);
  container.setStyle(style);
}.toBehavior(Prototype.resizeTarget, "resize"));

BehaviorManager.register("centerVCard", {
  observer: function() { $$("div.vcard").invoke("verticallyCenter"); },
  enable: function() {
    Event.observe(Prototype.resizeTarget, "resize", this.observer);
  },
  disable: Prototype.emptyFunction
});

String.measureWidth = function measureWidth(str, style) {
  style = Object.extend({
    visibility: "hidden", top: "-100000em", left: "-100000em"
  }, style || {});
  var e = new Element("span").update(str);
  $(document.body).insert(e.setStyle(style));
  var width = e.measure("width");
  e.remove();
  return width;
}.lazify();
String.prototype.measureWidth = String.measureWidth.methodize();

function showPerson(dn) {
  $("phonebook-search").request({
    parameters: {format: "html", keyword: dn.dnToEmail()},
    onSuccess: function onSuccess(r) {
      $(document.body).addClassName("lightbox");
      var close = new Element("div").observe("click", function(e) {
        $(document.body).removeClassName("lightbox");
      }).addClassName("close-button").writeAttribute("title", "Close");
      $("overlay").update('').update(r.responseText).
                   down("div.vcard").verticallyCenter().
                   down("div.header").insert(close);
      $("overlay").down(".vcard p.manager a").observe("click", function() {
        $(document.body).removeClassName("lightbox");
      });
    }
  });
}

function graphST() {
  var duration = 250, container = $("container"),
      tooltip = "Click to center and expand, double click to show card";
  var ht = new $jit.ST({
    injectInto: container,
    duration: duration, levelDistance: 75,
    transition: $jit.Trans.Quart.easeInOut,
    Navigation: { enable: true, panning: true },

    Node: {
      type: "rectangle", width: 30, height: 20,
      color: "#333", align: "left",
      overridable: true
    },
    Label: { type: "HTML", color: "#fff" },
    Edge: { type: "bezier", lineWidth: 2, color: "#333" },

    onCreateLabel: function onCreateLabel(elem, node) {
      $(elem).update(node.name).observe("click", function() {
        node.getSubnodes().length > 1 && ht.onClick(node.id);
      }).observe("dblclick", function() {
        showPerson(node.id);
      }).observe("mousedown", function(e) {
        e.stop();
      }).writeAttribute("title", tooltip);
    },

    onBeforePlotNode: function onBeforePlotNode(node) {
      node.data.$width = node.name.measureWidth() + 6;
    },

    onPlaceLabel: function onPlaceLabel(elem, node) {
      var height = node.data.$height || node.Config.height;
      $(elem).setStyle({height: height + "px"});
    }
  });
  $("container").setStyle({cursor: "move"}).store("viz", ht);

  ht.loadJSON(data);
  ht.compute();
  ht.onClick(ht.root);
}

$(document).on("dom:loaded", function() {
  $("main-nav").down("a.orgchart").addClassName("selected");
  $("orgchart-nav").down("a.folkgraph").addClassName("selected");
  BehaviorManager.enable("adjustCanvas");
  BehaviorManager.fire("adjustCanvas");
  BehaviorManager.enable("centerVCard");

  var overlay = new Element("div", {id: "overlay"});
  $(document.body).insert(overlay);
  $(overlay).observe("click", function(e) {
    if (e.element() == this) {
      $(document.body).removeClassName("lightbox");
    }
  });

  graphST();
});

/*
function graphHyperTree() {
  var dims = $("container").getDimensions();
  var ht = new $jit.Hypertree({
    injectInto: "container",
    width: dims.width,
    height: dims.height,

    Node: { dim: 9, color: "#fff" },
    Edge: { lineWidth: 2, color: "#acd1e3" },

    onCreateLabel: function onCreateLabel(elem, node) {
      $(elem).update(node.name).on("click", function() {
        ht.onClick(node.id);
      });
    },

    onPlaceLabel: function onPlaceLabel(elem, node) {
      var e = $(elem).setStyle({cursor: "pointer"});
      e.setStyle({fontSize: (1 / node._depth) + "em"});
      e.setStyle({marginTop: "3px", marginLeft: -(e.getWidth() / 2) + "px"});
    }
  });

  ht.loadJSON(data);
  ht.compute();
  ht.plot();
}
*/

