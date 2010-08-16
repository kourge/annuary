
class PhonebookApp
  class TreeBroker
    def roots() raise NotImplementedError end
  end

  require 'views/node'
  Views::Node.template_path = File.join(File.dirname(__FILE__), 'templates')

  get '/tree' do
    mustache :tree
  end
end

