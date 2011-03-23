
module PhonebookApp::Views
  class Results < Mustache
    def initialize(results, keyword)
      self.template_name = self.template_name.split("/")[-1]

      @results = results
      @keyword = keyword
    end
    def content_type() raise NotImplementedError end
  end
end

