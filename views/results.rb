
module PhonebookApp::Views
  class Results < Mustache
    def initialize(results, keyword)
      @results = results
      @keyword = keyword
    end
    def content_type() raise NotImplementedError end
  end
end

