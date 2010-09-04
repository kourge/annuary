Annuary
=======
Annuary is the codename of the internal Phonebook used at Mozilla. The name is
a crosslingual play on words: the French word for a phone book is "annuaire".

Requirements
------------
Annuary uses several Ruby gems:

* [sinatra](http://www.sinatrarb.com/)
* [net/ldap](http://github.com/RoryO/ruby-net-ldap)
* [json](http://flori.github.com/json/)
* [mustache](http://github.com/defunkt/mustache)
* [QuickMagick](http://quickmagick.rubyforge.org/quick_magick/), which requires
  you to have [ImageMagick](http://www.imagemagick.org/) installed on your 
  system.
* [vPim](http://vpim.rubyforge.org/)

Most gems can be installed by simply running:

    $ gem install <gem_name>

`sudo` at your own discretion. On Ruby < 1.8.7, some gems may not install and 
complain about your Ruby version being too old. In that case, run: 

    $ gem install <gem_name> -f

This forces `gem` to proceed with the installation.

Configuration
-------------
Use the included `config-sample.yaml` file as a template to create 
`config.yaml`. The file should look like this:

    ldap:
      # Indeed, LDAP option names must start with a colon.
      :host: 'ldap.example.com'
      :port: 636
      :encryption: :simple_tls
    memcache:
      enabled: true
      servers:
        - "localhost:11211"
    photo:
      mime_type: 'image/jpeg'
      thumbnail_dimensions: '140x175>'

### LDAP ###
The specified LDAP server will be used to both read and write entry data. It's
generally a good idea to have an encrypted LDAP connection. Changes are made
with the accessing user's LDAP account.

### Memcache ###
If memcache is enabled and alive servers are given, certain cache-needy
operations will automatically use memcache.

### Photo ###
The output MIME type of entry photos is usually `image/jpeg`, since it is
standard LDAP practice to store photos in the `jpegPhoto` attribute. Thumbnail 
dimensions are specified in [ImageMagick's geometry
syntax](http://www.imagemagick.org/script/command-line-processing.php#geometry).

Running on CGI
--------------
A useful `dispatch.cgi` file has been provided to facilitate running Annuary
through CGI. The following `mod_rewrite` rules may be useful in conjunction
with `dispatch.cgi`:

    RewriteEngine On
    RewriteBase /
    RewriteRule ^(.*)$ dispatch.cgi [L,QSA,E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

