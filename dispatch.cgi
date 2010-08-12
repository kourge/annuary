#!/usr/bin/ruby
# vim:set filetype=ruby:

require 'rubygems'
require 'rack'
require File.join(File::dirname(__FILE__), 'app.rb')

class PhonebookApp
  enable :show_exceptions
  set :environment => :development
end

# PATH_INFO is not always populated by default for some reason.
ENV['PATH_INFO'] ||= ENV['REQUEST_URI'].split('?').first

# Rack::Auth::Basic::Request#basic? cannot handle an empty HTTP_AUTHORIZATION.
ENV['HTTP_AUTHORIZATION'] = nil if ENV['HTTP_AUTHORIZATION'] == ''

Rack::Handler::CGI.run(PhonebookApp)

