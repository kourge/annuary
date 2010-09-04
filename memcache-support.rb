
begin
  require 'memcache'
rescue LoadError
  nil
end if SETTINGS['memcache']['enabled']

module Memcachable

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # memcachify can take any arbritrary method and memoize it through a
    # memcache connection. It does this by calling Array#hash on the arguments
    # array and using the resulting hash to form the memcache entry key, so
    # multiple arguments are not problematic unless the arguments do not have
    # consistent hashing behavior.
    #
    # It also attempts to do the right thing when a setter (i.e. a method with
    # a name ending in =) is memcachified by invalidating the entry that might 
    # have been inserted by the corresponding getter. The original setter is
    # always called.
    #
    # Although memcachify doesn't disallow it, memcachifying a destructive
    # method (i.e. a method with a name ending in !) is generally a bad idea.
    #
    #   $memcache_connection = MemCache.new('localhost:11211')
    #   class Calendar
    #     extend Memcacheable
    #
    #     def [](from, to)
    #       # something computationally expensive
    #     end
    #
    #     memcachify :[], 'daterange', $memcache_connection
    #   end
    def memcachify(method, id, connection)
      original = self.instance_method(method)
      if method.to_s =~ /=$/
        # We're dealing with a setter
        self.send(:define_method, method) do |*args|
          connection.delete(id + '(' + args[0..-2].hash.to_s + ')')
          original.bind(self).call(*args) 
        end
      else
        self.send(:define_method, method) do |*args|
          key = id + '(' + args.hash.to_s + ')'
          value = connection.get(key)
          return value unless value.nil?
          value = original.bind(self).call(*args)
          connection.set(key, value)
          value
        end
      end
    end
  end

end

class PhonebookApp
  def self.memcache() @@memcache end

  if SETTINGS['memcache']['enabled'] and defined? MemCache
    @@memcache = MemCache.new(SETTINGS['memcache']['servers']) 
    if not @@memcache.active? or not @@memcache.servers.any? { |s| s.alive? }
      @@memcache = nil
    end
  else
    @@memcache = nil
  end
end 

