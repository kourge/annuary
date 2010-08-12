require 'net/ldap'


module Auth

  # The DN class is responsible for constructing a DN given a key piece of
  # information, i.e. an email address or a login alias. Conversely, when 
  # given a valid DN, it should parse and make available useful information 
  # from the DN.
  class DN
    def dn() raise NotImplementedError end
    def mail() raise NotImplementedError end
    def o() raise NotImplementedError end

    def initialize(data) raise NotImplementedError end

    # In charge of determining if a particular entry has rights as a phonebook
    # admin. A phonebook admin can generally edit the entries of others.
    def phonebook_admin?() raise NotImplementedError end
  end

  def self.ldap_connection() Net::LDAP.new(SETTINGS['ldap']) end

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
    def realm() 'LDAP - Valid User Required' end
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


