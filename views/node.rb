
module PhonebookApp::Views
  class Node < Mustache
    def initialize(entry, lookup)
      @entry = entry
      @lookup = lookup

      @children = @lookup.delete(entry.dn) || []
      @leaf = @children.empty?

      @children.sort!
    end

    def id() @entry.mail.first.sub(/@/, '-at-') end
    def name() @entry.cn.first end
    def title() @entry[:title].first end
    def url() '#search/' + @entry.mail.first end
    def leaf?() @leaf end
    def disabled?() @entry.employeetype.first == 'DISABLED' end

    def children()
      @children.map { |entry| self.class.new(entry, @lookup) }
    end

    def classes()
      classes = ['hr-node', 'expanded']
      classes << 'leaf' if self.leaf?
      classes << 'disabled' if self.disabled?
      classes.join(' ')
    end
  end
end

