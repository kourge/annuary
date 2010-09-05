
SearchManager.startSearch = function() {
  if (!$F("text").strip()) {
    return;
  }
  $("text").releaseFocus();
  if (BehaviorManager.disable("centerHeader")) {
    $("phonebook-search").removeClassName("large");
  }
  $("phonebook-search").request({onSuccess: function onSuccess(r) {
    $("results").update('').update(r.responseText || this.notFoundMessage);
  }.bind(this)});
};

$(document).observe("dom:loaded", function() {
  $("main-nav").down("a.card").addClassName("selected");

  BehaviorManager.enable("slashSearch");
  SearchManager.initialize();
});

