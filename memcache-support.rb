
begin
  require 'memcache'
rescue LoadError
  nil
end if SETTINGS['memcache']['enabled']

class PhonebookApp
  def self.memcache() @@memcache end

  if SETTINGS['memcache']['enabled'] and defined? MemCache
    @@memcache = MemCache.new(
      SETTINGS['memcache']['host'].to_s + ':' + SETTINGS['memcache']['port'].to_s
    ) 
    if (not @@memcache.active?) or (not @@memcache.servers.any? { |s| s.alive? })
      @@memcache = nil
    end
  else
    @@memcache = nil
  end

  module MemcachableRead
    def [](key)
      return self.get(key) unless PhonebookApp.memcache
      # Retrieve from memcache otherwise
    end
  end

  module MemcachableWrite
    def []=(key, value)
      return self.set(key, value) unless PhonebookApp.memcache
    end
  end

  module MemcachableReadWrite
    include MemcachableRead
    include MemcachableWrite
  end
end 

