
require 'vpim/vcard'

module PhonebookApp::Views
  class VcardResults < Results
    def content_type() 'text/x-vcard' end

    def yield
      @results.map { |entry|
        e = Card.new(entry)

        card = Vpim::DirectoryInfo.create([
          Vpim::DirectoryInfo::Field.create('VERSION', '2.1')
        ], 'VCARD')
        Vpim::Vcard::Maker.make2(card) do |m|
          m.name do |n|
            n.given = e.given_name
            n.family = e.sn
          end
          m.add_email(e.mail)
          e.email_aliases.each { |addr| m.add_email(addr) }
          e.mobile.each { |num| m.add_tel(num) }
          m.title = e.title if e.title
          m.org = e.org
          m.add_tel('650-903-0800 x' + e.extension) if e.extension?
        end

        card.to_s
      }.join("---\n")
    end
  end
end

