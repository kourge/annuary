
module PhonebookApp::Views
  class OrgchartDot < Orgchart
    def content_type() 'text/plain; charset=utf-8' end
    def headers()
      {'Content-Disposition' => 'attachment; filename="orgchart.gv"'}
    end

    def initialize()
      @g = %Q(graph orgchart {
  graph [charset="UTF-8"];
  node [shape="Mrecord"];
  )
      n = "\n"

      search = PhonebookApp::Search.new('*')
      search.base = 'o=com,dc=mozilla'
      search.attributes = ['cn', 'manager', 'sn', 'givenName']
      results = search.results
      results.each do |entry|
        @g << %Q(\n  "#{entry.dn}" [label="#{entry.givenname[0]}\\n#{entry.sn[0]}"];)
      end
      results.each do |entry|
        next if entry[:manager].empty?
        @g << %Q(\n  "#{entry.dn}" -- "#{entry.manager[0]}";)
      end
      @g << "\n}"
    end

    def yield() @g end
  end
end

