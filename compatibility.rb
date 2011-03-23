
class Regexp
  class << self
    alias :_union :union
    def union(*a)
      a = a[0] if a[0].kind_of? Array
      self._union *a
    end
  end
end if RUBY_VERSION < '1.8.7'

module Fix; end unless defined? Fix

module Fix::IOFix
  def getbyte; self.getc; end
end if RUBY_VERSION < '1.8.7'

class IO
  include Fix::IOFix if RUBY_VERSION < '1.8.7'
end

require 'stringio' unless defined? StringIO
class StringIO
  include Fix::IOFix if RUBY_VERSION < '1.8.7'
end

# On 1.9, IO#getbyte returns a one-char string but on 1.8.x it returns a
# Fixnum. Thus doing foo.getc.ord can fail; this fixes that.
class Fixnum
  def ord; self; end
end if RUBY_VERSION < '1.8.7'

class Object
  def tap
    yield self
    self
  end if RUBY_VERSION < '1.9'
end

