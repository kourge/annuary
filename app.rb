load 'compatibility.rb' if RUBY_VERSION < '1.9'

require 'sinatra/base'
require 'mustache/sinatra'
require 'json'
require 'yaml'

load 'augmentations.rb'
load 'preamble.rb'


class PhonebookApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :mustache, {
    :views => File.expand_path('views/'),
    :templates => File.expand_path('templates/')
  }
  Mustache.raise_on_context_miss = true

  register Mustache::Sinatra
  require 'views/layout'

  get '/' do
    mustache :cards
  end

  get '/faces' do
    mustache :faces
  end
end


load 'memcache-support.rb'
load 'flash.rb'
load 'auth.rb'
load 'search.rb'
load 'photo.rb'
load 'edit.rb'
load 'orgchart.rb'
load 'whosthat.rb'
load 'local-pre.rb' if PhonebookApp.development? and File.exist?('local-pre.rb')
load 'organization.rb'
load 'local.rb' if PhonebookApp.development? and File.exist?('local.rb')


