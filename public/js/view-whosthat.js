
BehaviorManager.register("adjustColumnLayout", function() {
  var photo = $("photo"), question = $("question");
  [photo, question].invoke("setStyle", {
    marginTop: $("header").measure("margin-box-height") + "px"
  });

  var pic = photo.down("img");
  pic && pic.verticallyCenter();
  var q = $("question-cluster");
  q && q.verticallyCenter();
}.toBehavior(Prototype.resizeTarget, "resize"));

var GuessingGame = {
  candidates: null,
  score: 0,
  streak: 0,
  _index: 0,
  _rindex: 0,
  _timer: null,

  start: function start() {
    this.names = this.candidates.clone();
    [this.candidates, this.names].invoke("shuffle");
    this.preloadImage(this.candidates[0].thumbURL);
    this.photo = $("photo");
    this.scoreArea = $("score");
    this.streakArea = $("streak");
    this.questionsArea = $("question");
    this.caption = $("caption");
    this.options = $("options");
    this.next();
  },

  next: function next() {
    /* fade out */ this.questionsArea.hide();
    this.caption.update("Who's that Mozillian?");

    if (this._index >= this.candidates.length) {
      this._index = 0;
      this.candidates.shuffle();
    }
    this.preloadImage(this.candidates[this._index + 1].thumbURL);
    var nextPerson = this.candidates[this._index++];

    this.photo.update('');
    var image = new Element("img", {src: nextPerson.thumbURL});
    this.photo.insert(image);

    var name = null, randomNames = [];
    while (randomNames.length != 3 && (name = this.getRandom())) {
      if (name.cn == nextPerson.cn) {
        continue;
      }
      randomNames.push(name);
    }
    var names = randomNames.pluck("cn").concat([nextPerson.cn]).shuffle();
    this.options.update('');
    names.each(function(name) {
      var button = new Element("button", {"class": "option"}).update(name);
      var caption = this.caption;
      button.observe("click", function(e) {
        this._timer = setTimeout(GuessingGame.next.bind(GuessingGame), 2000);
        this.caption.update("It's " + nextPerson.cn + "!")
        image.wrap(new Element("a", {href: nextPerson.photoURL}));
        if (e.element().innerHTML.strip() == nextPerson.cn) {
          this.score += 5;
          this.streak++;
        } else {
          this.streak = 0;
        }
        this.updateScore();
      }.bind(this));
      this.options.insert(button);
    }.bind(this));
    /* fade in */ this.questionsArea.show();
    BehaviorManager.fire("adjustColumnLayout");
  },

  getRandom: function getRandom() {
    if (this._rindex >= this.names.length) {
      this._rindex = 0;
      this.names.shuffle();
    }
    return this.names[this._rindex++];
  },

  preloadImage: function preloadImage(url) {
    var i = new Image();
    i.src = url;
  },

  updateScore: function updateScore() {
    this.scoreArea.update(this.score);
    this.streakArea.update(this.streak);
  }
};

$(document).observe("dom:loaded", function() {
  $("menu").down("a.whosthat").addClassName("selected");

  BehaviorManager.enable("adjustColumnLayout");
  BehaviorManager.fire("adjustColumnLayout");

  BehaviorManager.enable("slashSearch");
  BehaviorManager.enable("cardSearchOnEnter");

  $("phonebook-search").request({
    parameters: {format: "json", keyword: "*"},
    onSuccess: function onSuccess(r) {
      var results = r.responseText.evalJSON();
      GuessingGame.candidates = results.select(function(person) {
        return person.hasPhoto;
      });
      GuessingGame.start();
    }.bind(this)
  });
});

