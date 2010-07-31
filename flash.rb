
require 'rack-flash'
class PhonebookApp
  use Rack::Flash, :accessorize => [:notice, :error]
end

