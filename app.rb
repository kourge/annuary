load 'compatibility.rb' if RUBY_VERSION < '1.8.7'

require 'sinatra/base'
require 'mustache/sinatra'
require 'json'
require 'yaml'

load 'augmentations.rb'
load 'preamble.rb'


class PhonebookApp < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :mustache, {:views => 'views/', :templates => 'templates/'}
  Mustache.raise_on_context_miss = true

  register Mustache::Sinatra
  require 'views/layout'

  get '/' do mustache :cards end
  get '/faces' do mustache :faces end
end


load 'memcache-support.rb'
load 'flash.rb'
load 'auth.rb'
load 'search.rb'
load 'photo.rb'
load 'organization.rb'


