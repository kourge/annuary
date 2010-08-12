# coding: utf-8

SETTINGS = YAML.load_file('config.yaml')

class PhonebookApp < Sinatra::Base
  mime_type :plain, 'text/plain'
  mime_type :html, 'text/html'
  mime_type :json, 'application/json'

  helpers do
    def accept_html?; request.accept.first == 'text/html' end
    def accept_json?; request.accept.first == 'application/json' end

    def redirect_back
      referer = request.referer
      if referer =~ /login|logout/ then redirect '/' else redirect referer end
    end

    def error(status_code, object)
      if accept_json?
        content_type :json
        halt status_code, {:error => object}.to_json
      else
        locals = {
          :exception? => object.kind_of?(Exception),
          :object => object, :status_code => status_code
        }
        halt status_code, mustache(:error, :locals => locals)
      end
    end

    include Rack::Utils
  end

  enable :sessions
end

