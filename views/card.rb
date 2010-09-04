
module PhonebookApp::Views
  class Card < Mustache
    attr_reader :entry

    def initialize(entry) # Net::LDAP::Entry
      @entry = entry
      @admin = nil
    end

    def admin?
      @admin.nil? ? @admin = Auth::DN.new(@entry.dn).phonebook_admin? : @admin
    end

    def dn() @entry.dn end
    def cn() @entry.cn.first end
    def sn() @entry.sn.first end
    def given_name() @entry.givenname.first end
    def mail() @entry.mail.first end

    def photo?() not @entry[:jpegphoto].empty? end
    def photo_url() './photo/' + self.mail end
    def thumb_url() './thumb/' + self.mail end
    def null_photo_url() './img/null.jpg' end

    def edit_url() './edit/' + self.mail end
    def vcard_url() './search?format=vcard&query=' + self.mail end

    def location
      location = @entry[:physicaldeliveryofficename].first
      return nil if location.nil?
      location.sub(/:::/, '/')
    end
    def extension() @entry[:telephonenumber].first end
    def extension?() not self.extension.nil? end
    def locality?() self.location or self.extension end

    def bugmail() @entry[:bugzillaemail].first end
    def title() @entry[:title].first end

    def employee_type()
      org, stat = PhonebookApp.employee_type(@entry)
      stat.nil? ? org : "#{org}, #{stat}"
    end

    def org()
      type = PhonebookApp.employee_type(@entry)
      return type.first if type.respond_to?(:first)
      type
    end

    def org_chart_url() './tree#search/' + mail end

    def manager
      manager = @entry[:manager].first
      return nil if manager.nil?
      PhonebookApp::QuickLookup[Auth::DN.new(manager).mail]
    end
    def manager_search_url() '.#search/' + self.manager[:mail].first end

    def tel
      lambda do |phone|
        return phone if phone !~ /\d/
        return phone if phone =~ /\(.+?\).+\(.+?\)/
        number = phone.sub(/\(.+\)\s*$/, '').sub(/.+:\s*/, '').strip
        number = Rack::Utils::escape_html(number)
        phone = Rack::Utils::escape_html(phone)
        "<a href=\"tel:#{number}\">#{phone}</a>"
      end
    end

    def mobile?() not @entry[:mobile].empty? end
    def mobile() @entry[:mobile] end

    def email_aliases() @entry[:emailalias] end

    def im?() not @entry[:im].empty? end
    def im() @entry[:im] end

    def wiki_format
      lambda do |markup|
        markup.gsub(/\n|\r\n/, '<br />').gsub(/\[(.+?)(?:\s(.+?))?\]/) do
          fst = Rack::Utils::escape_html($1)
          snd = Rack::Utils::escape_html($2)
          "<a href=\"#{fst}\">#{snd}</a>"
        end
      end
    end

    def i_work_on() @entry[:description].first end
    def other() @entry[:other].first end
  end
end

