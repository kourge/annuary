
module PhonebookApp::Views
  class Layout < Mustache
    def title
      @title || 'Mozilla Phonebook'
    end
  end
end

