
class PhonebookApp

  class Photo
    class << self
      def get(key) raise NotImplementedError end
      def set(key, value) raise NotImplementedError end

      include PhonebookApp::MemcachableReadWrite
    end
  end

  class Thumb
    class << self
      def get(key) raise NotImplementedError end

      include PhonebookApp::MemcachableRead
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

