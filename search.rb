
class PhonebookApp

  # The Search class is responsible for giving LDAP entry results when
  # initialized with @keyword set. Typically, you only need to override the
  # methods base, filter, and attributes. Implementing before_results will
  # cause the default results implementation to run the LDAP search results
  # through before_results as a filter.
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

  get '/directory.php' do
    redirect '/search/*?format=fligtar'
  end

  ['/search/:keyword', '/search', '/search.php'].each do |route|
    get route do
      keyword = params[:keyword] || params[:query]
      format = params[:format]
      results = Search.new(keyword).results
      if format == 'html'
        results.map { |entry| Views::Card.new(entry).render }.join
      elsif format.respond_to?(:downcase!)
        begin
          format.downcase!
          require "views/#{format}_results"
          const = format.capitalize + 'Results'
          raise LoadError if not Views.const_defined?(const)
          view = Views.const_get(const)
          view.template_path = File.join(File.dirname(__FILE__), 'templates')
          template = view.new(results, keyword)
          content_type template.content_type
          template.render
        rescue LoadError => e
          halt 400, "Invalid format specified"
        end
      else
        halt 400, "Invalid format specified"
      end
    end
  end
end

