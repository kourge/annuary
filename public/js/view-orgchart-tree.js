
Element.addMethods("li", {
  childTree: function childTree(element) {
    var next = $(element).next();
    return (next && next.match("ul")) ? next : undefined;
  },

  collapse: function collapse(element) {
    return $(element).addClassName("collapsed").removeClassName("expanded");
  },

  expand: function expand(element) {
    return $(element).addClassName("expanded").removeClassName("collapsed");
  },

  collapsed: function collapsed(element) {
    return $(element).hasClassName("collapsed");
  },

  expanded: function expanded(element) {
    return !$(element).collapsed();
  },

  toggleTree: function toggleTree(element) {
    element = $(element);
    return element[element.collapsed() ? "expand" : "collapse"]();
  }
});

BehaviorManager.register("scrollSnap", function() {
  var card = $("person").down("div.vcard");
  var tree = $("orgchart");
  if (!card || !tree) { return; }
  if (!card.retrieve("originalTop")) {
    card.store("originalTop", card.getStyle("marginTop"));
  }
  var refTop = tree.viewportOffset().top;
  card[refTop >= 5 ? "removeClassName" : "addClassName"]("snap-to-top");
}.toBehavior(document, "scroll"));

BehaviorManager.register("treeNodeToggling", function(e) {
  e.stop();
  !e.element().match("a") && $(this).toggleTree();
}.toBehavior(new Selector("div li.hr-node"), "click"));

BehaviorManager.register("preventSelectionWhileToggling", function(e) {
  e.stop();
}.toBehavior(new Selector("div li.hr-node"), "mousedown"));

BehaviorManager.register("treeNodeSelecting", function(e) {
  e.stop();
  Tree.doNotFilter = true;
  Tree.select($(this).up());
}.toBehavior(new Selector("div li.hr-node span.hit-target"), "click"));

BehaviorManager.register("clearFilterOnEsc", function(e) {
  (e.keyCode == Event.KEY_ESC) && Tree.clearFilter();
}.toBehavior("text", "keyup"));

BehaviorManager.register("clearFilterOnClick", {
  bound: false,

  onMouseDown: function onMouseDown(e) {
    e.findElement().addClassName("active");
  },
  onMouseUp: function onMouseUp(e) {
    e.findElement().removeClassName("active");
    this.fire();
  },
  onKeyUp: function onKeyUp(e) { this.update(); },

  update: function update(e) {
    (function() {
      this.button[$F("text") == "" ? "hide" : "show"]();
    }).bind(this).defer();
  },

  enable: function enable() {
    if (!this.bound) {
      $w("onMouseDown onMouseUp onKeyUp").each(function(e) {
        this[e] = this[e].bind(this);
      }.bind(this));
      this.bound = true;
    }
    $("text").addClassName("with-clear-button");
    this.button = new Element("div", {id: "clear-button"}).update("Clear");
    this.container = $("text").wrap("div", {id: "text-wrapper"});
    this.container.insert(this.button.writeAttribute("title", "Clear"));
    this.button.observe("mousedown", this.onMouseDown).
                observe("mouseup", this.onMouseUp);
    $("text").observe("keyup", this.onKeyUp);
    this.onKeyUp();
  },

  disable: function disable() {
    $("text").removeClassName("with-clear-button");
    this.button.stopObserving("mousedown", this.onMouseDown).
                stopObserving("mouseup", this.onMouseUp).
                remove();
    this.container.insert({before: $("text").remove()}).remove();
    $("text").stopObserving("keyup", this.onKeyUp);
  },

  fire: function fire() {
    Tree.clearFilter();
    this.button.hide();
    $("text").focus();
  }
});

BehaviorManager.register("filterOnSubmit", function(e) {
  e.stop();
  $("text").blur();
  if (!$F("text").strip()) {
    $$("#orgchart li:not(.leaf)").invoke("expand");
    return;
  }
  window.location.hash = "search/" + $F("text");
}.toBehavior("phonebook-search", "submit"));

var Tree = {
  doNotFilter: false,
  selected: null,
  select: function select(node) {
    this.selected && this.selected.removeClassName("selected");
    this.selected = $(node).addClassName("selected");
    window.location.hash = "search/" + this.selected.id.replace("-at-", '@');
  },

  clearFilter: function clearFilter() {
    (function() { $("text").clear(); }).defer();
    this.stopFiltering();
  },

  stopFiltering: function stopFiltering() {
    $("orgchart").removeClassName("filter-view");
    $$("#orgchart li.highlighted").invoke("removeClassName", "highlighted");
    $$("#orgchart li:not(.leaf)").invoke("expand");
  },

  showPerson: function showPerson(email) {
    new Ajax.Request("search.php", {
      method: "get",
      parameters: {query: email, format: "html"},
      onSuccess: function(r) {
        $("person").update(r.responseText || this.notFoundMessage).down(".vcard");
        BehaviorManager.fire("scrollSnap");
      }
    });
  },

  filter: function filter() {
    $("phonebook-search").request({
      parameters: {format: "json"},
      onSuccess: function onSuccess(r) {
        var people = r.responseText.evalJSON();
        var converter = this.dnToEmail || function(x) { return x.dnToEmail(); };
        people = people.pluck("dn").map(converter).compact();
        people.sort(function(a, b) {
          return a.cumulativeOffset().top - b.cumulativeOffset().top;
        });

        /*
        var allowedToShow = people.map(function(x) {
          var rootwards = x.ancestors().find("ul").compact().invoke("previous", "li");
          var leafwards = [];
          return [x].concat(rootwards).concat(leafwards).compact();
        });
        */

        if (people.length > 0) {
          //$$("#orgchart li:not(.leaf)").invoke("collapse");
          //allowedToShow.flatten().uniq().find(":not(.leaf)").invoke("expand");
          var item = people.first().addClassName("highlighted");
          var prev = this.flattened[this.flattened.indexOf(item.id) - 1];
          ($(prev) || $("orgchart")).scrollTo();
        } else {
          $("person").update(SearchManager.notFoundMessage || '');
        }
        $("orgchart").addClassName("filter-view");
      }.bind(this)
    });
  },

  setup: function setup() {
    this.flattened = $$("li.hr-node").pluck("id");
  }
};

Object.extend(SearchManager, {
  enabledBehaviorsOnInit: ["filterOnSubmit"],
  onHashChange: function onHashChange(e) {
    var query = e.memo.hash.replace("search/", '');
    $("text").value = query;
    Tree.stopFiltering();
    if (query.include('@')) {
      Tree.showPerson.bind(this)(query);
      Tree.select($(query.replace('@', "-at-")));
    }
    if (!Tree.doNotFilter) {
      Tree.filter();
    } else {
      BehaviorManager.update("clearFilterOnClick");
      Tree.doNotFilter = false;
    }
  },

  onLoad: function onLoad() {
    var hash = window.location.hash;
    if (hash.startsWith("#search/")) {
      var search = hash.replace(/^#search\//, '');
      if (!search.strip()) { return; }
      $("text").value = search;
      $(document).fire("hash:changed", {hash: hash.substring(1)});
    }
  }
});

$(document).observe("dom:loaded", function() {
  $("search").update("Filter");
  $("main-nav").down("a.orgchart").addClassName("selected");
  $("orgchart-nav").down("a.tree").addClassName("selected");

  BehaviorManager.enable("scrollSnap");
  BehaviorManager.enable("treeNodeToggling");
  BehaviorManager.enable("preventSelectionWhileToggling");
  BehaviorManager.enable("treeNodeSelecting");
  BehaviorManager.enable("slashSearch");
  BehaviorManager.enable("clearFilterOnEsc");
  BehaviorManager.enable("clearFilterOnClick");

  Tree.setup();

  SearchManager.initialize();
});

Object.extend(Tree, {
  dnToEmail: function dnToEmail(x) {
    var e = x.dnToEmail();
    return e ? $(e.replace('@', "-at-")) : null;
  }
});

