
module PhonebookApp::Views
  class OrgchartFolkgraph < Orgchart
    ROOTS = [
      'mail=lilly@mozilla.com,o=com,dc=mozilla',
      'mail=mitchell@mozilla.com,o=com,dc=mozilla',
      'mail=dascher@mozilla.com,o=com,dc=mozilla'
    ]

    def content_type() 'text/html' end

    def initialize()
    end
  end
end
