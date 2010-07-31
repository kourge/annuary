
class PhonebookApp
  class Search
    def initialize(keyword)
      @keyword = keyword
    end

    def base() raise NotImplementedError end
    def filter() raise NotImplementedError end
    def attributes() raise NotImplementedError end

    def results
      results = Auth.ldap_connection_as_user.search(
        :base => self.base, :attributes => self.attributes,
        :filter => self.filter
      )
      results = self.before_results(results) if self.respond_to? :before_results
      results
    end
  end

  require 'views/card'
  require 'views/results'
  Views::Card.template_path = File.join(File.dirname(__FILE__), 'templates')
  Views::Results.template_path = File.join(File.dirname(__FILE__), 'templates')

  ['/search/:keyword', '/search', '/search.php'].each do |route|
    get route do
      results = Search.new(params[:keyword] || params[:query]).results
      if params[:format] == 'html'
        results.map { |entry| Views::Card.new(entry).render }.join
      else
        begin
          require "views/#{params[:format].downcase}_results"
          const = params[:format].downcase.capitalize + 'Results'
          raise LoadError.new if not Views.const_defined?(const)
          view = Views.const_get(const)
          view.template_path = File.join(File.dirname(__FILE__), 'templates')
          template = view.new(results)
          content_type template.content_type
          template.render
        rescue LoadError
          halt 400, "Invalid format specified"
        end
      end
    end
  end
end

