
module PhonebookApp::Views
  require 'views/node' if not defined?(Node)
  Node.template_path = PhonebookApp.mustache[:templates]

  class OrgchartTree < Orgchart
    ROOTS = [
      'mail=lilly@mozilla.com,o=com,dc=mozilla',
      'mail=mitchell@mozilla.com,o=com,dc=mozilla',
      'mail=dascher@mozilla.com,o=com,dc=mozilla'
    ]

    def content_type() 'text/html' end

    def initialize()
      @roots = []
      @people = {}
      @orphans = []

      search = PhonebookApp::Search.new('*')
      search.base = 'o=com,dc=mozilla'
      search.attributes = ['cn', 'mail', 'title', 'manager', 'employeetype']
      search.results.each do |person|
        if not person[:manager].empty?
          (@people[person.manager.first] ||= []) << person
        elsif ROOTS.include?(person.dn)
          @roots << person
        elsif not person[:mail].empty?
          @orphans << person if not ROOTS.include?(person.dn)
        end
      end
    end

    def principal_tree()
      @roots.map { |root| Node.new(root, @people).render }.join
    end

    def orphans()
      (@orphans + @people.values.flatten).sort!.map do |entry|
        Node.new(entry, {})
      end
    end
  end
end

