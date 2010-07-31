
module PhonebookApp::Views
  class Results < Mustache
    def initialize(results) @results = results end
    def content_type() raise NotImplementedError end
  end
end

