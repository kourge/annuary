
module PhonebookApp::Views
  class Card < Mustache
    attr_reader :entry

    def initialize(entry) # Net::LDAP::Entry
      @entry = entry
      @admin = nil
    end

    def admin?
      if @admin.nil?
        @admin = Auth.ldap_connection_as_user.search(
          :base => 'ou=groups,dc=mozilla',
          :filter => "(&(member=#{@entry.dn})(cn=phonebook_admin))",
          :attributes => ['cn'], :attributes_only => true
        ).length > 0
      end
      @admin
    end

    def dn() @entry.dn end
    def cn() @entry.cn.first end
    def mail() @entry.mail.first end

    def photo_url() '/photo/' + self.mail end
    def thumb_url() '/thumb/' + self.mail end

    def edit_url() '/edit/' + self.mail end
    def vcard_url() '/search?format=vcard&query=' + self.mail end

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
      type = @entry.employeetype.first
      return 'Unknown' if type.nil? or type == 'OK'
      parts = type.split('')
      return 'Disabled' if parts.include?('D')
      org = case parts[0]
        when 'C' then 'Mozilla Corporation'
        when 'F' then 'Mozilla Foundation'
        when 'J' then 'Mozilla Japan'
        when 'M' then 'Mozilla Messaging'
        when 'O' then 'Mozilla Online'
      end
      stat = case parts[1]
        when 'E' then 'Employee'
        when 'I' then 'Intern'
        when 'C' then 'Contractor'
      end
      "#{org}, #{stat}"
    end

    def org_chart_url() '/tree#search/' + mail end

    def manager
      manager = @entry[:manager].first
      return nil if manager.nil?
      PhonebookApp::Search.new(Auth::DN.new(manager).mail).results.first
    end
    def manager_search_url() '#search/' + self.manager.mail.first end

    def tel
      lambda do |phone|
        return phone if phone !~ /\d/
        return phone if phone =~ /\(.+?\).+\(.+?\)/
        number = phone.sub(/\(.+\)\s*$/, '').sub(/.+:\s*/, '').strip
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
          "<a href=\"#{$1}\">#{$2}</a>"
        end
      end
    end

    def i_work_on() @entry[:description].first end
    def other() @entry[:other].first end
  end
end

