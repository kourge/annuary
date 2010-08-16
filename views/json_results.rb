
module PhonebookApp::Views
  class JsonResults < Results
    def content_type() 'application/json' end

    def yield
      @results.map do |entry|
        e = Card.new(entry)
        hash = {
          :dn => e.dn, :mail => e.mail, :cn => e.cn, :title => e.title,
          :extension => e.extension, :mobile => e.mobile, 
          :description => e.i_work_on, :other => e.other, :im => e.im, 
          :emailAliases => e.email_aliases, :bugmail => e.bugmail,
          :location => e.entry[:physicaldeliveryofficename].first,
          :employeeType => e.employee_type.split(', '),
          :manager => e.manager ? {
            :dn => e.manager[:dn].first, :cn => e.manager[:cn].first
          } : nil,
          :photoURL => e.photo_url, :thumbURL => e.thumb_url,
          :hasPhoto => e.photo?
        }
      end.to_json
    end
  end
end

