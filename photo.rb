
class PhonebookApp

  class Photo
    class << self
      def get(key) raise NotImplementedError end
      def set(key, value) raise NotImplementedError end

      def [](key) self.get(key) end
      def []=(key, value)
        self.set(key, value)
        Thumb[key] = nil
      end
    end
  end

  # You should generally use [] and []= to read / write, since they are
  # memoized through memcache if possible. get and set are responsible for the
  # raw operations of fetching / writing data from / to LDAP, so override these
  # to implement the actual code to do so.
  class Thumb
    class << self
      def get(key) raise NotImplementedError end
      def set(key) nil end

      def [](key) self.get(key) end
      def []=(key, value) self.set(key) end
      def invalidate(key) self[key] = nil end

      if SETTINGS['memcache']['enabled'] and PhonebookApp.memcache
        extend PhonebookApp::Memcachable
        memcachify :[], 'phonebook:thumb'
        memcachify :[]=, 'phonebook:thumb'
      end
    end
  end

  get '/photo/:mail' do |mail|
    content_type SETTINGS['photo']['mime_type']
    Photo[mail]
  end

  get '/thumb/:mail' do |mail|
    content_type SETTINGS['photo']['mime_type']
    Thumb[mail]
  end

  get '/pic.php' do
    mail = request[:mail]
    halt 404 if not mail
    content_type SETTINGS['photo']['mime_type']
    request[:type] == 'thumb' ? Thumb[mail] : Photo[mail]
  end
end
