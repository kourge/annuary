require 'net/ldap'


module Auth
  # The DN class is responsible for parsing various info out of an email address.
  class DN
    def dn() raise NotImplementedError end
    def mail() raise NotImplementedError end
    def o() raise NotImplementedError end

    def initialize(mail)
      raise NotImplementedError
    end
  end

  def self.ldap_connection
    Net::LDAP.new(
      :host => SETTINGS['ldap']['host'], :port => SETTINGS['ldap']['port']
    )
  end

  def self.ldap_connection_as_user
    ldap = self.ldap_connection
    ldap.auth(DN.new(PhonebookApp.username).dn, PhonebookApp.password)
    ldap
  end

  # Actually checks credentials using the LDAP server.
  def self.authorized?(username, password)
    return false if not username or not password

    ldap = self.ldap_connection
    ldap.auth(DN.new(username).dn, password)
    ldap.bind # bind returns a boolean
  end
end


class PhonebookApp
  class LDAPAuth < Rack::Auth::Basic
    def realm; 'LDAP - Valid User Required' end
  end

  def self.username() @@username end
  def self.password() @@password end

  use LDAPAuth do |username, password|
    # Class variables are used because this block's scope is tied to the 
    # PhonebookApp class but routes are tied to instances of the class.
    @@username, @@password = username, password
    Auth.authorized?(username, password)
  end
end


