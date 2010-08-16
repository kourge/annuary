
$(document).observe("dom:loaded", function() {
  BehaviorManager.enable("slashSearch");
  BehaviorManager.enable("cardSearchOnEnter");

  $("edit-entry").addClassName("selected").removeAttribute("href");
  var params = window.location.search.toQueryParams();
  if (params.mail || params.edit_mail) {
    $("edit-entry").update("Edit Entry");
  }

  var countryMap = {
    'Mountain View': 'US',
    'Auckland': 'NZ',
    'Beijing': 'CN',
    'Denmark': 'DK',
    'Paris': 'FR',
    'Toronto': 'CA',
    'Tokyo': 'JP' 
  };
  var officeCitySelect = $$("select[name=office_city]")[0];
  var officeCityName = $$("input[name=office_city_name]")[0];
  officeCitySelect && officeCitySelect.observe("change", function(e) {
    var city = $F(this);
    officeCityName[city == "Other" ? "show" : "hide"]();
    if (countryMap[city] && city != "Other") {
      $$("select[name=office_country]")[0].value = countryMap[city];
    }
  });
  officeCitySelect && $F(officeCitySelect) != "Other" && officeCityName.hide();

  var orgType = $$("select[name=org_type]")[0];
  orgType && orgType.observe("change", function(e) {
    var hireType = $$("select[name=hire_type]")[0];
    ($F(this) == '') && hireType && (hireType.value = '');
  });
  
  var remover = function(e) {
    e.element().up().remove();
    e.stop();
  };
  var attachRemove = function(e, title) {
    var a = new Element("a", {href: '#', title: title});
    a.observe("click", remover).addClassName("remove-link");
    e.insert({after: a});
  };
  var adder = function(name, title) {
    return function(e) {
      var input = new Element("input", {type: "text", name: name});
      var wrapper = input.wrap('div');
      e.element().up().insert({before: wrapper});
      attachRemove(input, "Remove " + title);
      e.stop();
      input.focus();
    };
  };

  // Attach add link
  $$("tr.multiple").each(function(field) {
    var title = field.readAttribute('data-item');
    var name = field.readAttribute('data-name');
    var container = field.down("td.container");

    var addLink = new Element("a", {href: '#'}).update("Add " + title);
    addLink.addClassName('add-link').observe("click", adder(name, title));
    container.insert(addLink.wrap('div'));
  });

  // Attach remove links for existing fields
  $$("tr.multiple").map(function(field) {
    var title = field.readAttribute('data-item');
    var name = field.readAttribute('data-name');
    $(field).select("input").each(function(input) {
      attachRemove(input, "Remove " + title);
    });
  });

  // Replace dumb combobox with an autocomplete textbox
  var manager = new Element("input", {type: "text", id: "manager-text"});
  var dropdown = $$("select[name=manager]")[0];
  dropdown.hide().insert({before: manager});
  manager.value = $$("option[value='#{dn}']".interpolate({
    dn: $F(dropdown)
  }))[0].innerHTML;

  new Autocomplete(manager, {
    serviceUrl: "./search?format=autocomplete",
    minChars: 2,
    onSelect: function(value, data) {
      $(dropdown).value = data;
    }
  });

});

