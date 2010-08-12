
class PhonebookApp
  # A number of form field names have changed, so Reannuaire compatibility 
  # is not retained for editing. No one's using it as an API anyway.

  get '/edit' do
    params[:mail] ||= PhonebookApp.username
    @entry = Search.new(params[:mail]).results.first
    error 403, 'Forbidden' if not EditBroker.new(@params).allowed?
    error 404, 'Not found' if @entry.nil?
    mustache :edit
  end

  # The EditBroker will initialize @params as incoming parameters from the POST
  # request. The methods allowed?, valid?, and commit will each be called 
  # exactly once, in that order.
  class EditBroker
    class InvalidFieldError < StandardError; end

    def initialize(params) @params = params end

    # Return false if the current user is not allowed to edit the entry in 
    # question. Otherwise return true.
    def allowed?() raise NotImplementedError end

    # Raise an InvalidFieldError when a field is found to be invalid. The
    # message of the exception will be shown to the client. Otherwise, return
    # true.
    def valid?() raise NotImplementedError end

    # Write changes to the LDAP server in this method. Exceptions raised in
    # this method will also be reported to the client. Recoverable errors
    # should be returned as an array of OpenStructs.
    def commit!() raise NotImplementedError end
  end

  post '/edit' do
    edit = EditBroker.new(@params)
    error 403, 'Forbidden' if not edit.allowed?

    begin
      edit.valid?
    rescue EditBroker::InvalidFieldError => e
      error 400, "Invalid field: #{e.message}"
    end


    begin
      errors = edit.commit!
    rescue Exception => e
      error 400, e
    end

    if accept_json?
      errors.to_json
    else
      if errors.empty?
        flash.notice 'The changes have been saved.'
      else
        list = errors.map { |x| '<li>' + escape_html(x) + '</li>' }.join
        flash.error "The following error(s) occured: <ul>#{list}</ul>"
      end
      redirect_back
    end
  end
end

