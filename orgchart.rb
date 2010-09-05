
class PhonebookApp
  require 'views/orgchart'
  Views::Orgchart.template_path = mustache[:templates]

  get %r{/orgchart\|(.+)} do |repr|
    begin
      repr.downcase!
      require "views/orgchart_#{repr}"
      const = 'Orgchart' + repr.capitalize
      raise LoadError if not Views.const_defined?(const)

      view = Views.const_get(const)
      view.template_path = PhonebookApp.mustache[:templates]
      template = view.new

      type = template.content_type
      content_type type
      headers template.headers if template.respond_to?(:headers)

      if type == 'text/html'
        Views::Layout.template_path = PhonebookApp.mustache[:templates]
        layout = Views::Layout.new
        orgchart = Views::Orgchart.new
        orgchart[:yield] = template.render
        layout[:yield] = orgchart.render
        layout.render
      else
        template.render
      end
    rescue LoadError => e
      halt 400, "Invalid orgchart view specified"
    end
  end
end

