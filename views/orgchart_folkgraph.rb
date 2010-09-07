
module PhonebookApp::Views
  class OrgchartFolkgraph < Orgchart
    ROOTS = [
      'mail=lilly@mozilla.com,o=com,dc=mozilla',
      'mail=mitchell@mozilla.com,o=com,dc=mozilla',
      'mail=dascher@mozilla.com,o=com,dc=mozilla'
    ]

    def content_type() 'text/html' end

    def initialize()
      @root = nil
      @people = {}

      search = PhonebookApp::Search.new('*')
      search.base = 'o=com,dc=mozilla'
      search.attributes = ['cn', 'mail', 'title', 'manager', 'employeetype']
      search.results.each do |person|
        if not person[:manager].empty?
          (@people[person.manager.first] ||= []) << person
        end
        @root = person if person.dn == ROOTS.first
      end  
    end  

    def yield() Node.new(@people, @root).to_json end
  end  

  class Node
    def initialize(source, entry) @source, @entry = source, entry end

    def to_json(*a)
      {
        :id => @entry.dn, :name => @entry.cn.first,
        :children => (@source[@entry.dn] || []).map do |child|
          self.class.new(@source, child)
        end
      }.to_json(*a)
    end
  end
end
