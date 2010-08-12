
module PhonebookApp::Views
  class Layout < Mustache
    def flash
      flash = PhonebookApp.flash
      @flash = []
      flash.flag!.each do |type|
        @flash << {:type => type, :message => flash[type]}
      end
      @flash
    end

    def title
      @title || 'Mozilla Phonebook'
    end
  end
end

