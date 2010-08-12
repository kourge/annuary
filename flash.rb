
require 'rack-flash'
class PhonebookApp
  use Rack::Flash, :accessorize => [:notice, :error]

  def self.flash() @@flash end
  before do
    @@flash = self.flash
  end
end

