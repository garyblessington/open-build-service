# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'opensuse/permission'
require 'opensuse/ldap'
require 'opensuse/backend'
require 'opensuse/validator'
require 'rexml/document'
require 'api_exception'

class ApplicationController < ActionController::API

  class InvalidHttpMethodError < APIException
    setup 'invalid_http_method'
  end
  class MissingParameterError < APIException
    setup 'missing_parameter'
  end
  class InvalidParameterError < APIException
    setup "invalid_parameter"
  end

  include ActionController::MimeResponds

  # session :disabled => true

  @user_permissions = nil
  @http_user = nil
  @skip_validation = false

  before_filter :validate_xml_request, :add_api_version
  if CONFIG['response_schema_validation'] == true
    after_filter :validate_xml_response
  end

  # skip the filter for the user stuff
  before_filter :extract_user
  before_filter :setup_backend
  before_filter :shutup_rails
  before_filter :set_current_user
  before_filter :validate_params

  #contains current authentification method, one of (:proxy, :basic)
  attr_accessor :auth_method

  hide_action :auth_method
  hide_action 'auth_method='

  protected
  def set_current_user
    User.current = @http_user
  end

  def require_admin
    logger.debug "Checking for  Admin role for user #{@http_user.login}"
    unless @http_user.is_admin?
      logger.debug "not granted!"
      render_error :status => 403, :errorcode => "put_request_no_permission", :message => "Requires admin privileges" and return false
    end
    return true
  end

  def http_anonymous_user
    return User.find_by_login( "_nobody_" )
  end

  def extract_user_public
    # to become _public_ special user
    if CONFIG['allow_anonymous']
      @http_user = User.find_by_login( "_nobody_" )
      @user_permissions = Suse::Permission.new( @http_user )
      return true
    end
    logger.error "No public access is configured"
    render_error( :message => "No public access is configured", :status => 401 )
    return false
  end

  def validate_params
    params.each do |key, value|
      next if value.nil?
      next if key == 'xmlhash' # perfectly fine
      if !value.kind_of? String
        raise InvalidParameterError, "Parameter #{key} has non String class #{key.class}"
      end
    end
  end

  def extract_user
    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(CONFIG, request.env)

    Rails.logger.debug "DEBUG: ENGINE #{auth_engine.engine.inspect}"

    return false unless auth_engine.engine

    @http_user, message = auth_engine.authenticate

    if @http_user.nil? && auth_engine.is_a?(Opensuse::Authentication::IchainEngine) && auth_engine.user_login
      if CONFIG['new_user_registration'] == "deny"
        logger.debug( "No user found in database, creation disabled" )
        message = "User 'CONFG' does not exist"
      end
      state = User.states['confirmed']
      state = User.states['unconfirmed'] if CONFIG['new_user_registration'] == "confirmation"
      # Generate and store a fake pw in the OBS DB that no-one knows
      # FIXME: we should allow NULL passwords in DB, but that needs user management cleanup
      chars = ["A".."Z","a".."z","0".."9"].collect { |r| r.to_a }.join
      fakepw = (1..24).collect { chars[rand(chars.size)] }.pack("a"*24)
      @http_user = User.create(
        :login => proxy_user,
        :password => fakepw,
        :password_confirmation => fakepw,
        :state => state
      )

      @http_user.update_user_info_from_proxy_env(request.env) unless @http_user.nil?
    end

    if @http_user.nil?
      render_error( :message => message, :status => 401 ) and return false
    else
      if @http_user.state == User.states['ichainrequest'] or @http_user.state == User.states['unconfirmed']
        render_error :message => "User is registered but not yet approved.", :status => 403,
          :errorcode => "unconfirmed_user",
          :details => "<p>Your account is a registered account, but it is not yet approved for the OBS by admin.</p>"
        return false
      end

      if @http_user.state == User.states['confirmed']
        logger.debug "USER found: #{@http_user.login}"
        @user_permissions = Suse::Permission.new( @http_user )
        return true
      end
    end

    render_error :message => "User is registered but not in confirmed state.", :status => 403,
      :errorcode => "inactive_user",
      :details => "<p>Your account is a registered account, but it is in a not active state.</p>"
    return false
  end

  hide_action :setup_backend
  def setup_backend
    # initialize backend on every request
    Suse::Backend.source_host = CONFIG['source_host']
    Suse::Backend.source_port = CONFIG['source_port']
  end

  hide_action :add_api_version
  def add_api_version
    response.headers["X-Opensuse-APIVersion"] = "#{CONFIG['version']}"
  end

  hide_action :forward_from_backend
  def forward_from_backend(path)

    # apache & mod_xforward case
    if CONFIG['use_xforward'] and CONFIG['use_xforward'] != "false"
      logger.debug "[backend] VOLLEY(mod_xforward): #{path}"
      headers['X-Forward'] = "http://#{CONFIG['source_host']}:#{CONFIG['source_port']}#{path}"
      head(200)
      @skip_validation = true
      return
    end

    # lighttpd 1.5 case
    if CONFIG['x_rewrite_host']
      logger.debug "[backend] VOLLEY(lighttpd): #{path}"
      headers['X-Rewrite-URI'] = path
      headers['X-Rewrite-Host'] = CONFIG['x_rewrite_host']
      head(200)
      @skip_validation = true
      return
    end

    logger.debug "[backend] VOLLEY: #{path}"
    Suse::Backend.start_test_backend
    backend_http = Net::HTTP.new(CONFIG['source_host'], CONFIG['source_port'])
    backend_http.read_timeout = 1000

    # we have to be careful with object life cycle. the actual data is
    # deleted once the tempfile is garbage collected, but isn't kept alive
    # as the send_file function only references the path to it. So we keep it
    # for ourselves. And once the controller is garbage collected, it should
    # be fine to unlink the data
    @volleyfile = Tempfile.new 'volley', :encoding => 'ascii-8bit'
    opts = { :url_based_filename => true }

    backend_http.request_get(path) do |res|
      opts[:status] = res.code
      opts[:type] = res['Content-Type']
      res.read_body do |segment|
        @volleyfile.write(segment)
      end
    end
    opts[:length] = @volleyfile.length
    # streaming makes it very hard for test cases to verify output
    opts[:stream] = false if Rails.env.test?
    send_file(@volleyfile.path, opts)
    # close the file so it's not staying in the file system
    @volleyfile.close
  end

  hide_action :download_request
  def download_request
    file = Tempfile.new 'volley', :encoding => 'ascii-8bit'
    b = request.body
    buffer = String.new
    while b.read(40960, buffer)
      file.write(buffer)
    end
    file.close
    file.open
    file
  end

  def pass_to_backend( path = nil )

    unless path
      path = request.path
      if not request.query_string.blank?
        path = path + '?'+request.query_string
      elsif not request.env["rack.request.form_vars"].blank?
        path = path + '?' + request.env["rack.request.form_vars"]
      end
    end

    case request.method.to_s.downcase
    when "get"
      forward_from_backend( path )
      return
    when "post"
      file = download_request
      response = Suse::Backend.post( path, file )
      file.close!
    when "put"
      file = download_request
      response = Suse::Backend.put( path, file )
      file.close!
    when "delete"
      response = Suse::Backend.delete( path )
    end

    text = response.body
    send_data( text, :type => response.fetch( "content-type" ),
      :disposition => "inline" )
    return text
  end
  public :pass_to_backend

  rescue_from ActiveRecord::RecordInvalid do |exception|
    render_error status: 400, errorcode: "invalid_record", message: exception.record.errors.full_messages.join('\n')
  end

  rescue_from ActiveXML::Transport::Error do |exception|
    render_error status: exception.code, errorcode: "uncaught_exception", message: exception.summary
  end

  rescue_from Timeout::Error do |exception|
    render_error status: 408, errorcode: "timeout_error", message: exception.message
  end

  rescue_from APIException do |exception|
    logger.debug "#{exception.class.name} #{exception.message}"
    message = exception.message
    if message.blank?
      message = exception.default_message
    end
    render_error message: message, status: exception.status, errorcode: exception.errorcode
  end

  rescue_from Suse::Backend::HTTPError do |exception|
    xml = REXML::Document.new( exception.message )
    http_status = xml.root.attributes['code']
    unless xml.root.attributes.include? 'origin'
      xml.root.add_attribute "origin", "backend"
    end
    xml_text = String.new
    xml.write xml_text
    render :text => xml_text, :status => http_status
  end

  rescue_from Suse::Backend::NotFoundError, ActiveRecord::RecordNotFound do |exception|
    render_error message: exception.message, status: 404, errorcode: 'not_found'
  end

  def permissions
    return @user_permissions
  end

  def user
    return @http_user
  end

  def required_parameters(*parameters)
    parameters.each do |parameter|
      unless params.include? parameter.to_s
        raise MissingParameterError, "Required Parameter #{parameter} missing"
      end
    end
  end

  def valid_http_methods(*methods)
    list = methods.map {|x| x.to_s.downcase}
    unless list.include? request.method.to_s.downcase
      raise InvalidHttpMethodError, "Invalid HTTP Method: #{request.method.to_s.upcase}"
    end
  end

  def render_error( opt = {} )
    # workaround an exception in mod_rails, it dies when an answer is send without
    # reading the body. We trigger passenger to read the entire body via requesting the size
    if request.put? or request.post?
      request.body.size if request.body.respond_to? 'size'
    end

    if opt[:message]
      @summary = opt[:message]
    elsif @exception
      @summary = @exception.message
    end

    @exception = opt[:exception]
    @details = opt[:details]
    @errorcode = opt[:errorcode]

    opt[:status] ||= 400

    if opt[:status].to_i == 401
      response.headers["WWW-Authenticate"] = 'basic realm="API login"'
    end
    if opt[:status].to_i == 404
      @summary ||= "Not found"
      @errorcode ||= "not_found"
    end

    @summary ||= "Internal Server Error"

    if @exception
      @errorcode ||= 'uncaught_exception'
    end

    @errorcode ||= 'unknown'

    response.headers['X-Opensuse-Errorcode'] = @errorcode
    render :template => 'status', :status => opt[:status]
  end

  def render_ok(opt={})
    # keep compatible to old call style
    opt = {:details => opt} if opt.kind_of? String

    @errorcode = "ok"
    @summary = "Ok"
    @details = opt[:details] if opt[:details]
    @data = opt[:data] if opt[:data]
    render :template => 'status', :status => 200
  end

  def render_invoked(opt={})
    @errorcode = "invoked"
    @summary = "Job invoked"
    @details = opt[:details] if opt[:details]
    @data = opt[:data] if opt[:data]
    render :template => 'status', :status => 200
  end

  def backend
    Suse::Backend.start_test_backend if Rails.env.test?
    @backend ||= ActiveXML.transport
  end

  def backend_get( path )
    # TODO: check why not using SUSE:Backend::get
    backend.direct_http( URI(path) )
  end

  def backend_put( path, data )
    backend.direct_http( URI(path), :method => "PUT", :data => data )
  end

  def backend_post( path, data )
    backend.set_additional_header("Content-Length", data.size.to_s())
    response = backend.direct_http( URI(path), :method => "POST", :data => data )
    backend.delete_additional_header("Content-Length")
    return response
  end

  # Passes control to subroutines determined by action and a request parameter. By
  # default the parameter assumed to contain the command is ':cmd'. Looks for a method
  # named <action>_<command>
  #
  # Example:
  #
  # If you call dispatch_command from an action 'index' with the query parameter cmd
  # having the value 'show', it will call the method 'index_show'
  #
  def dispatch_command(opt={})
    defaults = {
      :cmd_param => :cmd
    }
    opt = defaults.merge opt
    unless params.has_key? opt[:cmd_param]
      render_error :status => 400, :errorcode => "missing_parameter",
        :message => "Missing parameter '#{opt[:cmd_param]}'"
      return
    end

    cmd_handler = "#{params[:action]}_#{params[opt[:cmd_param]]}"
    logger.debug "dispatch_command: trying to call method '#{cmd_handler}'"

    if not self.respond_to? cmd_handler, true
      render_error :status => 400, :errorcode => "unknown_command",
        :message => "Unknown command '#{params[opt[:cmd_param]]}' for path #{request.path}"
      return
    end

    __send__ cmd_handler
  end
  public :dispatch_command
  hide_action :dispatch_command


  def build_query_from_hash(hash, key_list=nil)
    Suse::Backend.build_query_from_hash(hash, key_list)
  end

  def query_parms_missing?(*list)
    missing = Array.new
    for param in list
      missing << param unless params.has_key? param
    end

    if missing.length > 0
      render_error :status => 400, :errorcode => "missing_query_parameters",
        :message => "Missing query parameters: #{missing.join ', '}"
    end
    return false
  end

  def min_votes_for_rating
    return CONFIG["min_votes_for_rating"]
  end

  private
  def shutup_rails
    Rails.cache.silence!
  end

  def action_fragment_key( options )
    # this is for customizing the path/filename of cached files (cached by the
    # action_cache plugin). here we want to include params in the filename
    par = params
    par.delete 'controller'
    par.delete 'action'
    pairs = []
    par.sort.each { |pair| pairs << pair.join('=') }
    url_for( options ).split('://').last + "/"+ pairs.join(',').gsub(' ', '-')
  end

  def log_process_action(payload)
     messages = super
     puts "LPA #{messages.join}"
     messages
  end

end
