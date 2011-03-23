
module PhonebookApp::Views
  class Edit < Layout
    def admin?() Auth::DN.new(@entry.dn).phonebook_admin? end

    def mail() @entry.mail.first end

    def cn
      self.singular_text(
        :name => 'cn', :label => 'Name', :value => @entry.cn.first
      )
    end

    def email_alias
      self.multiple_text(
        :name => 'email_alias', :label => 'Other E-mail Address(es)',
        :item => 'e-mail', :values => @entry[:emailalias]
      )
    end

    def manager
      search = PhonebookApp::Search.new('*')
      search.attributes = ['cn']
      results = search.results.sort! { |a, b| a.cn.first <=> b.cn.first }
      self.dropdown(
        :name => 'manager', :selected => @entry[:manager].first || '',
        :options => [self.empty_option] + results.map do |entry|
          {:label => entry.cn.first, :value => entry.dn}
        end
      )
    end

    def office_city
      cities = PhonebookApp::CITIES
      city = @entry[:physicaldeliveryofficename].first
      city = city.split(':::')[0] if city
      value = city ? %Q( value="#{city}") : ''
      self.dropdown(
        :name => 'office_city', :label => 'Office City',
        :selected => cities.include?(city) ? city : 'Other',
        :options => cities.map do |city| {:label => city, :value => city} end,
        :addendum => %Q(
          <input type="text" name="office_city_name"#{value} />
        )
      )
    end

    def office_country
      countries = PhonebookApp::COUNTRIES
      country = @entry[:physicaldeliveryofficename].first
      country = country.split(':::')[1] if country
      top_key = 'UNITED STATES'
      top = countries.delete(top_key)
      options = countries.keys.sort.map do |key|
        {:label => key, :value => countries[key]}
      end
      options.unshift({:label => top_key, :value => top})
      options.unshift(self.empty_option)
      self.dropdown(
        :name => 'office_country', :label => 'Office Country',
        :options => options, :selected => country
      )
    end

    def job_title
      self.singular_text(:name => 'title', :value => @entry[:title].first)
    end

    def employee_type
      PhonebookApp.employee_type(@entry).join(', ')
    end

    def community?() @entry[:employeetype].first == 'OK' end
    def community() 'Community Member' end

    def organization_types
      organizations = PhonebookApp::ORGANIZATIONS
      current = @entry[:employeetype].first
      self.select(
        :name => 'org_type',
        :selected => current ? current.split('')[0] : '',
        :options => [self.empty_option] + organizations.keys.sort.map do |key|
          {:label => organizations[key], :value => key}
        end
      )
    end

    def hire_types
      hire_types = PhonebookApp::HIRE_TYPES
      current = @entry[:employeetype].first
      self.select(
        :name => 'hire_type',
        :selected => current ? current.split('')[1] : '',
        :options => [self.empty_option] + hire_types.keys.sort.map do |key|
          {:label => hire_types[key], :value => key}
        end
      )
    end

    def extension
      self.singular_text(
        :name => 'extension', :value => @entry[:telephonenumber].first
      )
    end

    def mobile
      self.multiple_text(
        :name => 'mobile', :label => 'Phone Number(s)', :item => 'number',
        :values => @entry[:mobile]
      )
    end

    def im
      self.multiple_text(
        :name => 'im', :label => 'IM Account(s)', :item => 'account',
        :values => @entry[:im]
      )
    end

    def bugmail
      self.singular_text(
        :name => 'bugmail', :value => @entry[:bugzillaemail].first,
        :description => 'Your full Bugzilla email address with no extra cruft'
      )
    end

    def i_work_on
      self.textarea(
        :name => 'description', :label => 'I work on',
        :value => @entry[:description].first
      )
    end

    def other
      self.textarea(:name => 'other', :value => @entry[:other].first)
    end

    def thumb_url() '/thumb/' + @entry.mail.first end
    def accept() %w(image/jpeg image/png).join(';') end
    def photo_description() 'JPEG and PNG are supported' end



    def escape_fields(field)
      field.keys.each do |k|
        field[k] = case k
          when :values then field[k].map { |v| Rack::Utils::escape_html(v) }
          when :options, :addendum then field[k]
          else Rack::Utils::escape_html(field[k])
        end
      end
      field
    end

    def singular_text(field)
      field = self.escape_fields(field)
      field[:label] = field[:name].capitalize if field[:label].nil?
      desc = if field[:description].nil?
        nil
      else
        desc = %Q(<br /><em class="description">#{field[:description]}</em>)
      end
      %Q(
      <tr>
        <td><label>#{field[:label]}</label></td>
        <td><input type="text" name="#{field[:name]}" value="#{field[:value]}" />
            #{desc}
        </td>
      </tr>
      )
    end

    def multiple_text(field)
      field = self.escape_fields(field)
      items = field[:values].map do |value|
        %Q(<div><input type="text" name="#{field[:name]}[]" value="#{value}" /></div>)
      end.join("\n")
      %Q(
      <tr class="multiple" data-item="#{field[:item]}"
                           data-name="#{field[:name]}[]">
        <td><label>#{field[:label]}</label></td>
        <td class="container">
#{items}
        </td>
      </tr>
      )
    end

    def dropdown(field)
      field = self.escape_fields(field)
      field[:label] = field[:name].capitalize if field[:label].nil?
      select_element = self.select(field)
      addendum = field[:addendum] || ''
      %Q(
      <tr class="select">
        <td><label>#{field[:label]}</label></td>
        <td>
          #{select_element}
          #{addendum}
        </td>
      </tr>
      )
    end

    def select(field)
      options = field[:options].map do |opt|
        selected = opt[:value] == field[:selected] ? ' selected="selected"' : ''
        %Q(<option value="#{opt[:value]}"#{selected}>#{opt[:label]}</option>)
      end.join("\n")
      %Q(
        <select name="#{field[:name]}">
#{options}
        </select>
      )
    end

    def empty_option() {:label => '', :value => ''} end

    def textarea(field)
      field = self.escape_fields(field)
      link = 'http://en.wikipedia.org/wiki/Help:Wikitext_examples#External_links'
      field[:label] = field[:name].capitalize if field[:label].nil?
      field[:description] ||=
        %Q(Links in <a href="#{link}">wiki markup</a> style supported.)
      desc = %Q(<br /><em class="description">#{field[:description]}</em>)
      %Q(
      <tr class="textarea">
        <td><label>#{field[:label]}</label></td>
        <td><textarea cols="40" rows="5" name="#{field[:name]}">#{field[:value]}</textarea>
            #{desc}
        </td>
      </tr>
      )
    end
  end
end

