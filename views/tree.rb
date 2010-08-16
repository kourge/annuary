
module PhonebookApp::Views
  class Tree < Layout
    def initialize()
      @roots = []
      @people = {}
      @orphans = []
      @tree = PhonebookApp::TreeBroker.new

      search = PhonebookApp::Search.new('*')
      search.base = 'o=com,dc=mozilla'
      search.attributes = ['cn', 'mail', 'title', 'manager', 'employeetype']
      search.results.each do |person|
        if not person[:manager].empty?
          (@people[person.manager.first] ||= []) << person
        elsif @tree.roots.include?(person.dn)
          @roots << person
        elsif not person[:mail].empty?
          @orphans << person if not @tree.roots.include?(person.dn)
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

