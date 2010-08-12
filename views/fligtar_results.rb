
module PhonebookApp::Views
  class FligtarResults < Results
    def content_type() 'application/json' end

    def yield
      hash = {}
      @results.each do |entry|
        e = Card.new(entry)
        hash[e.mail] = {
          :name => e.cn, :title => e.title, :ext => e.extension,
          :phones => self.unbox(e.mobile), :ims => self.unbox(e.im)
        }
      end
      hash.to_json
    end

    def unbox(object)
      if object.nil? or not object.kind_of?(Array)
        return object
      elsif object.empty?
        return nil
      else
        return object.length > 1 ? object : object.first
      end
    end
  end
end

