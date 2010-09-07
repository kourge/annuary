# coding: utf-8

module Auth
  class DN
    attr_reader :dn, :mail, :o

    def initialize(string)
      if string.index(',')
        @dn = string
        @mail, @o = @dn.split(',')[0..1].map { |part| part.split('=')[1] }
      else
        match = string.match /^[a-z.]+@(.+?)\.(.+)$/
        o = case [match[1], match[2]]
          when ['mozilla', 'com'], ['mozilla-japan', 'org'] then 'com'
          when ['mozilla', 'org'], ['mozillafoundation', 'org'] then 'org'
          else 'net'
        end
        @dn = "mail=#{string},o=#{o},dc=mozilla"
        @mail = string
        @o = o
      end
    end

    def phonebook_admin?
      Auth.ldap_connection_as_user.search(
        :base => 'ou=groups,dc=mozilla', :attributes => [],
        :filter => "(&(member=#{@dn})(cn=phonebook_admin))"
      ).length > 0
    end
  end
end

require 'quick_magick'

class PhonebookApp
  module EntryRank
    def <=>(other) self.cn.first <=> other.cn.first end
  end

  class Net::LDAP::Entry
    include EntryRank
  end

  class Photo
    # These are class methods, not instance methods.
    def self.get(dn)
      entry = Auth.ldap_connection_as_user.search(
        :base => dn, :attributes => 'jpegPhoto'
      ).first
      # nil is returned when entry doesn't exist or does not have a jpegPhoto.
      entry.nil? ? entry : entry[:jpegphoto].first
    end

    def self.set(dn, blob)
      img = QuickMagick::Image.from_blob(blob).first
      img.format = 'jpeg'
      blob = img.to_blob
      Auth.ldap_connection_as_user.replace_attribute(dn, :jpegPhoto, blob)
      blob
    end
  end


  class Thumb
    # These are class methods, not instance methods.
    def self.get(dn)
      img = QuickMagick::Image.from_blob(Photo[dn]).first
      img.resize(SETTINGS['photo']['thumbnail_dimensions'])
      img.to_blob
    end
  end


  # Enables the ~= ("approximately equals") LDAP operator. This is not a long 
  # term solution.
  class Filter < Net::LDAP::Filter
    def self.approx(attribute, value) self.new(:approx, attribute, value) end

    def to_ber
      if @op == :approx
        return [@left.to_s.to_ber, unescape(@right).to_ber].to_ber_contextspecific(8)
      end
      super
    end

    define_method(method_defined?(:to_raw_rfc2254) ? :to_raw_rfc2254 : :to_s) do
      return "(#{@left}~=#{@right})" if @op === :approx
      super
    end
  end


  class Search
    attr_accessor :base, :attributes

    def initialize(keyword)
      @keyword = keyword
      self.base = 'dc=mozilla'
      self.attributes = %w(
        cn title telephoneNumber mobile description manager other im mail
        emailAlias physicalDeliveryOFficeName employeeType isManager 
        bugzillaEmail
      )
    end

    def filter
      f = Filter
      keyword = self.class.escape_ldap_filter(@keyword)
      if @keyword == '*'
        f.eq('objectClass', 'mozComPerson')
      elsif @keyword =~ /.+@.+\..+/
        f.eq('mail', keyword)
      else
        f.eq('objectClass', 'mozComPerson') & (
          f.eq('cn', "*#{keyword}*") |
          f.eq('mail', "*#{keyword}*") |
          f.approx('im', keyword)
        )
      end
    end

    def self.escape_ldap_filter(string)
      string.gsub(/[\\*()\0]/) { |c| "\\#{c}" }
    end
  end

  get '/search.php' do redirect '/search?' + request.query_string end
  get '/faces.php' do redirect '/faces' end
  get '/directory.php' do redirect '/search/*?format=fligtar' end
  get '/tree.php' do redirect '/orgchart|tree' end
  get '/orgchart' do redirect '/orgchart|tree' end


  # QuickLookup mainly facilitates in quickly looking up managers and their
  # full names. The memcaching happens at the granularity of per entry, not per
  # attribute of an entry. This means if any attribute in ATTRIBUTES_TO_CACHE
  # is updated, then QuickLookup.invalidate should be called with the entry's
  # email address.
  class QuickLookup
    ATTRIBUTES_TO_CACHE = ['dn', 'cn', 'mail', 'manager']
    class << self
      def [](id)
        search = Search.new(id)
        search.attributes = ATTRIBUTES_TO_CACHE
        results = search.results.first
        return nil if results.nil?
        hash = {}
        ATTRIBUTES_TO_CACHE.each { |k| hash[k.to_sym] = results[k] }
        hash
      end

      def []=(id, whatnot) nil end
      def invalidate(id) self[id] = nil end

      if PhonebookApp.memcache
        include Memcachable
        memcachify :[], 'phonebook:quicklookup', PhonebookApp.memcache
        memcachify :[]=, 'phonebook:quicklookup', PhonebookApp.memcache
      end
    end
  end


  def self.employee_type(entry)
    type = entry.employeetype.first
    return 'Unknown' if type.nil?
    return 'Community Member' if type == 'OK'
    return 'Disabled' if type.upcase == 'DISABLED'
    parts = type.split('')
    [ORGANIZATIONS[parts[0]], HIRE_TYPES[parts[1]]]
  end

  ORGANIZATIONS = {
    'C' => 'Mozilla Corporation',
    'F' => 'Mozilla Foundation',
    'J' => 'Mozilla Japan',
    'M' => 'Mozilla Messaging',
    'O' => 'Mozilla Online'
  }

  HIRE_TYPES = {
    'E' => 'Employee',
    'I' => 'Intern',
    'C' => 'Contractor'
  }


  class EditBroker
    def admin?()
      if @admin.nil?
        @admin = Auth::DN.new(PhonebookApp.username).phonebook_admin?
      end
      @admin
    end

    def allowed?() @params[:mail] == PhonebookApp.username or self.admin? end

    FIELD_PLURALITIES = {
      :cn => String,
      :email_alias => Array,
      :manager => String,
      :office_city => String,
      :office_country => String,
      :title => String,
      :extension => String,
      :mobile => Array,
      :im => Array,
      :bugmail => String,
      :description => String,
      :other => String
    }

    def valid?
      p = @params

      errors = {
        String => 'should not be singular',
        Array => 'should not be plural'
      }
      # Verify the plurality of parameters that'll always be there.
      FIELD_PLURALITIES.each do |name, type|
        if not p[name].kind_of?(type)
          raise InvalidFieldError, name + ' ' + errors[type]
        end
      end

      # Validate manager DN
      manager_exists = Auth.ldap_connection_as_user.search(
        :base => p[:manager], :attributes => ['dn']
      ).length == 1
      raise InvalidFieldError, 'Invalid manager' if not manager_exists

      if not PhonebookApp::CITIES.include?(p[:office_city])
        raise InvalidFieldError, 'Invalid office city'
      end

      if not PhonebookApp::COUNTRIES.values.include?(p[:office_country])
        raise InvalidFieldError, 'Invalid office country'
      end

      if self.admin?
        organizations = PhonebookApp::ORGANIZATIONS.keys
        hire_types = PhonebookApp::HIRE_TYPES.keys
        valid_type = /^(|[#{organizations.join}][#{hire_types.join}])$/
        type = p[:org_type] + p[:hire_type]
        raise InvalidFieldError, 'Invalid employee status' if type !~ valid_type
      end

      if p[:photo] and p[:photo][:type] !~ /^image/
        raise InvalidFieldError, 'Photo is not an image'
      end

      true
    end

    FIELD_ATTRIBUTE_MAP = {
      :cn => :cn,
      :email_alias => :emailalias,
      :manager => :manager,
      :location => :physicaldeliveryofficename,
      :title => :title,
      :extension => :telephonenumber,
      :mobile => :mobile,
      :im => :im,
      :bugmail => :bugzillaemail,
      :description => :description,
      :other => :other
    }

    ADMIN_FIELD_ATTRIBUTE_MAP = {
      :employee_type => :employeetype 
    }

    def commit!
      p = @params
      QuickLookup.invalidate(p[:mail])

      # Rewrite phase.
      if p[:office_city] and p[:office_country]
        p[:office_city] = p[:office_city_name] if p[:office_city] == 'Other'
        p[:location] = p[:office_city] + ':::' + p[:office_country]
      end

      if p[:photo]
        blob = p[:photo][:tempfile].read
        require 'quick_magick'
        img = QuickMagick::Image.from_blob(blob).first
        img.format = 'jpeg'
        p[:photo] = img.to_blob
        FIELD_ATTRIBUTE_MAP.merge!({:photo => :jpegphoto})
      end

      if self.admin?
        p[:employee_type] = (p[:org_type] || '') + (p[:hire_type] || '')
        p[:employee_type] = 'DISABLED' if p[:employee_type] == ''
        p[:employee_type] = 'OK' if p[:employee_type][0, 1] == 'P'
      end

      # Write phase
      errors = []
      conn = Auth.ldap_connection_as_user
      dn = Auth::DN.new(p[:mail]).dn

      FIELD_ATTRIBUTE_MAP.merge!(ADMIN_FIELD_ATTRIBUTE_MAP) if self.admin?
      FIELD_ATTRIBUTE_MAP.each do |field, attribute|
        conn.replace_attribute(dn, attribute, p[field])
        result = conn.get_operation_result
        if result.code != 0
          result.attribute = attribute
          errors << result
        end
      end

      errors
    end
  end


  COUNTRIES = {
    "UNITED STATES" => "US",
    "AFGHANISTAN" => "AF",
    "ALAND ISLANDS" => "AX", # "ÅLAND"
    "ALBANIA" => "AL",
    "ALGERIA" => "DZ",
    "AMERICAN SAMOA" => "AS",
    "ANDORRA" => "AD",
    "ANGOLA" => "AO",
    "ANGUILLA" => "AI",
    "ANTARCTICA" => "AQ",
    "ANTIGUA AND BARBUDA" => "AG",
    "ARGENTINA" => "AR",
    "ARMENIA" => "AM",
    "ARUBA" => "AW",
    "AUSTRALIA" => "AU",
    "AUSTRIA" => "AT",
    "AZERBAIJAN" => "AZ",
    "BAHAMAS" => "BS",
    "BAHRAIN" => "BH",
    "BANGLADESH" => "BD",
    "BARBADOS" => "BB",
    "BELARUS" => "BY",
    "BELGIUM" => "BE",
    "BELIZE" => "BZ",
    "BENIN" => "BJ",
    "BERMUDA" => "BM",
    "BHUTAN" => "BT",
    "BOLIVIA" => "BO",
    "BOSNIA AND HERZEGOVINA" => "BA",
    "BOTSWANA" => "BW",
    "BOUVET ISLAND" => "BV",
    "BRAZIL" => "BR",
    "BRITISH INDIAN OCEAN TERRITORY" => "IO",
    "BRUNEI DARUSSALAM" => "BN",
    "BULGARIA" => "BG",
    "BURKINA FASO" => "BF",
    "BURUNDI" => "BI",
    "CAMBODIA" => "KH",
    "CAMEROON" => "CM",
    "CANADA" => "CA",
    "CAPE VERDE" => "CV",
    "CAYMAN ISLANDS" => "KY",
    "CENTRAL AFRICAN REPUBLIC" => "CF",
    "CHAD" => "TD",
    "CHILE" => "CL",
    "CHINA" => "CN",
    "CHRISTMAS ISLAND" => "CX",
    "COCOS (KEELING) ISLANDS" => "CC",
    "COLOMBIA" => "CO",
    "COMOROS" => "KM",
    "CONGO" => "CG",
    "CONGO, THE DEMOCRATIC REPUBLIC OF THE" => "CD",
    "COOK ISLANDS" => "CK",
    "COSTA RICA" => "CR",
    "CÔTE D'IVOIRE" => "CI",
    "CROATIA" => "HR",
    "CUBA" => "CU",
    "CYPRUS" => "CY",
    "CZECH REPUBLIC" => "CZ",
    "DENMARK" => "DK",
    "DJIBOUTI" => "DJ",
    "DOMINICA" => "DM",
    "DOMINICAN REPUBLIC" => "DO",
    "ECUADOR" => "EC",
    "EGYPT" => "EG",
    "EL SALVADOR" => "SV",
    "EQUATORIAL GUINEA" => "GQ",
    "ERITREA" => "ER",
    "ESTONIA" => "EE",
    "ETHIOPIA" => "ET",
    "FALKLAND ISLANDS (MALVINAS)" => "FK",
    "FAROE ISLANDS" => "FO",
    "FIJI" => "FJ",
    "FINLAND" => "FI",
    "FRANCE" => "FR",
    "FRENCH GUIANA" => "GF",
    "FRENCH POLYNESIA" => "PF",
    "FRENCH SOUTHERN TERRITORIES" => "TF",
    "GABON" => "GA",
    "GAMBIA" => "GM",
    "GEORGIA" => "GE",
    "GERMANY" => "DE",
    "GHANA" => "GH",
    "GIBRALTAR" => "GI",
    "GREECE" => "GR",
    "GREENLAND" => "GL",
    "GRENADA" => "GD",
    "GUADELOUPE" => "GP",
    "GUAM" => "GU",
    "GUATEMALA" => "GT",
    "GUERNSEY" => "GG",
    "GUINEA" => "GN",
    "GUINEA-BISSAU" => "GW",
    "GUYANA" => "GY",
    "HAITI" => "HT",
    "HEARD ISLAND AND MCDONALD ISLANDS" => "HM",
    "HOLY SEE (VATICAN CITY STATE)" => "VA",
    "HONDURAS" => "HN",
    "HONG KONG" => "HK",
    "HUNGARY" => "HU",
    "ICELAND" => "IS",
    "INDIA" => "IN",
    "INDONESIA" => "ID",
    "IRAN, ISLAMIC REPUBLIC OF" => "IR",
    "IRAQ" => "IQ",
    "IRELAND" => "IE",
    "ISLE OF MAN" => "IM",
    "ISRAEL" => "IL",
    "ITALY" => "IT",
    "JAMAICA" => "JM",
    "JAPAN" => "JP",
    "JERSEY" => "JE",
    "JORDAN" => "JO",
    "KAZAKHSTAN" => "KZ",
    "KENYA" => "KE",
    "KIRIBATI" => "KI",
    "KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF" => "KP",
    "KOREA, REPUBLIC OF" => "KR",
    "KUWAIT" => "KW",
    "KYRGYZSTAN" => "KG",
    "LAO PEOPLE'S DEMOCRATIC REPUBLIC" => "LA",
    "LATVIA" => "LV",
    "LEBANON" => "LB",
    "LESOTHO" => "LS",
    "LIBERIA" => "LR",
    "LIBYAN ARAB JAMAHIRIYA" => "LY",
    "LIECHTENSTEIN" => "LI",
    "LITHUANIA" => "LT",
    "LUXEMBOURG" => "LU",
    "MACAO" => "MO",
    "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF" => "MK",
    "MADAGASCAR" => "MG",
    "MALAWI" => "MW",
    "MALAYSIA" => "MY",
    "MALDIVES" => "MV",
    "MALI" => "ML",
    "MALTA" => "MT",
    "MARSHALL ISLANDS" => "MH",
    "MARTINIQUE" => "MQ",
    "MAURITANIA" => "MR",
    "MAURITIUS" => "MU",
    "MAYOTTE" => "YT",
    "MEXICO" => "MX",
    "MICRONESIA, FEDERATED STATES OF" => "FM",
    "MOLDOVA, REPUBLIC OF" => "MD",
    "MONACO" => "MC",
    "MONGOLIA" => "MN",
    "MONTENEGRO" => "ME",
    "MONTSERRAT" => "MS",
    "MOROCCO" => "MA",
    "MOZAMBIQUE" => "MZ",
    "MYANMAR" => "MM",
    "NAMIBIA" => "NA",
    "NAURU" => "NR",
    "NEPAL" => "NP",
    "NETHERLANDS" => "NL",
    "NETHERLANDS ANTILLES" => "AN",
    "NEW CALEDONIA" => "NC",
    "NEW ZEALAND" => "NZ",
    "NICARAGUA" => "NI",
    "NIGER" => "NE",
    "NIGERIA" => "NG",
    "NIUE" => "NU",
    "NORFOLK ISLAND" => "NF",
    "NORTHERN MARIANA ISLANDS" => "MP",
    "NORWAY" => "NO",
    "OMAN" => "OM",
    "PAKISTAN" => "PK",
    "PALAU" => "PW",
    "PALESTINIAN TERRITORY, OCCUPIED" => "PS",
    "PANAMA" => "PA",
    "PAPUA NEW GUINEA" => "PG",
    "PARAGUAY" => "PY",
    "PERU" => "PE",
    "PHILIPPINES" => "PH",
    "PITCAIRN" => "PN",
    "POLAND" => "PL",
    "PORTUGAL" => "PT",
    "PUERTO RICO" => "PR",
    "QATAR" => "QA",
    "REUNION" => "RE",
    "ROMANIA" => "RO",
    "RUSSIAN FEDERATION" => "RU",
    "RWANDA" => "RW",
    "SAINT BARTHÉLEMY" => "BL",
    "SAINT HELENA" => "SH",
    "SAINT KITTS AND NEVIS" => "KN",
    "SAINT LUCIA" => "LC",
    "SAINT MARTIN" => "MF",
    "SAINT PIERRE AND MIQUELON" => "PM",
    "SAINT VINCENT AND THE GRENADINES" => "VC",
    "SAMOA" => "WS",
    "SAN MARINO" => "SM",
    "SAO TOME AND PRINCIPE" => "ST",
    "SAUDI ARABIA" => "SA",
    "SENEGAL" => "SN",
    "SERBIA" => "RS",
    "SEYCHELLES" => "SC",
    "SIERRA LEONE" => "SL",
    "SINGAPORE" => "SG",
    "SLOVAKIA" => "SK",
    "SLOVENIA" => "SI",
    "SOLOMON ISLANDS" => "SB",
    "SOMALIA" => "SO",
    "SOUTH AFRICA" => "ZA",
    "SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS" => "GS",
    "SPAIN" => "ES",
    "SRI LANKA" => "LK",
    "SUDAN" => "SD",
    "SURINAME" => "SR",
    "SVALBARD AND JAN MAYEN" => "SJ",
    "SWAZILAND" => "SZ",
    "SWEDEN" => "SE",
    "SWITZERLAND" => "CH",
    "SYRIAN ARAB REPUBLIC" => "SY",
    "TAIWAN, PROVINCE OF CHINA" => "TW",
    "TAJIKISTAN" => "TJ",
    "TANZANIA, UNITED REPUBLIC OF" => "TZ",
    "THAILAND" => "TH",
    "TIMOR-LESTE" => "TL",
    "TOGO" => "TG",
    "TOKELAU" => "TK",
    "TONGA" => "TO",
    "TRINIDAD AND TOBAGO" => "TT",
    "TUNISIA" => "TN",
    "TURKEY" => "TR",
    "TURKMENISTAN" => "TM",
    "TURKS AND CAICOS ISLANDS" => "TC",
    "TUVALU" => "TV",
    "UGANDA" => "UG",
    "UKRAINE" => "UA",
    "UNITED ARAB EMIRATES" => "AE",
    "UNITED KINGDOM" => "GB",
    "UNITED STATES MINOR OUTLYING ISLANDS" => "UM",
    "URUGUAY" => "UY",
    "UZBEKISTAN" => "UZ",
    "VANUATU" => "VU",
    "VENEZUELA" => "VE",
    "VIET NAM" => "VN",
    "VIRGIN ISLANDS, BRITISH" => "VG",
    "VIRGIN ISLANDS, U.S." => "VI",
    "WALLIS AND FUTUNA" => "WF",
    "WESTERN SAHARA" => "EH",
    "YEMEN" => "YE",
    "ZAMBIA" => "ZM",
    "ZIMBABWE" => "ZW"
  }

  CITIES = [
    '', 'Mountain View', 'Auckland', 'Beijing', 'Denmark', 'Paris', 'Toronto',
    'Tokyo', 'Other'
  ]
end

