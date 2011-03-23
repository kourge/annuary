
module PhonebookApp::Views
  class Layout < Mustache
    def initialize
      self.template_name = self.template_name.split("/")[-1]
    end

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

