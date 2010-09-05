
require 'graphviz'

module PhonebookApp::Views
  class OrgchartDot < Orgchart
    def content_type() 'text/plain' end
    def headers()
      {'Content-Disposition' => 'attachment; filename="orgchart.gv"'}
    end

    def initialize()
      @g = GraphViz::new('orgchart', :type => :graph)
      n = "\n"

      search = PhonebookApp::Search.new('*')
      search.base = 'o=com,dc=mozilla'
      search.attributes = ['cn', 'manager', 'sn', 'givenName']
      results = search.results
      results.each do |entry|
        @g.add_node(entry.dn.md5).label = entry.givenname[0] + n + entry.sn[0]
      end
      results.each do |entry|
        next if entry[:manager].empty?
        @g.add_edge(entry.dn.md5, entry.manager[0].md5)
      end
    end

    def yield() @g.output(:dot => String) end
  end
end

