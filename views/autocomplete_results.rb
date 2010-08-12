
module PhonebookApp::Views
  class AutocompleteResults < Results
    def content_type() 'application/json' end

    def yield
      struct = {:query => @keyword, :suggestions => [], :data => []}
      @results.each do |entry|
        struct[:suggestions] << entry.cn.first
        struct[:data] << entry.dn
      end
      struct.to_json
    end
  end
end

