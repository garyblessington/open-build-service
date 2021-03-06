require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class CrowdEngineTest < ActiveSupport::TestCase
  def setup
    @configuration = {
      'crowd_url' => '127.0.0.1',
      'crowd_app_name' => 'obs-api',
      'crowd_app_password' => 'app_password'
    }

    ApplicationSettings::AuthCrowdServer.set!('127.0.0.1')
    ApplicationSettings::AuthCrowdAppName.set!('obs-api')
    ApplicationSettings::AuthCrowdAppPassword.set!('app_password')

    @environment = {}
  end

  def test_returns_nil_when_crowd_is_not_configured
    ApplicationSettings::AuthCrowdServer.set!(nil)
    ApplicationSettings::AuthCrowdAppName.set!(nil)
    ApplicationSettings::AuthCrowdAppPassword.set!(nil)

    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_crowd_is_not_configured
    ApplicationSettings::AuthCrowdServer.set!(nil)
    ApplicationSettings::AuthCrowdAppName.set!(nil)
    ApplicationSettings::AuthCrowdAppPassword.set!(nil)

    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal "No Crowd Application Configured", auth_engine.authenticate.last
  end

  def test_returns_nil_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_nil_when_app_authentication_to_crowd_fails
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"MyPassword\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'22', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 401, :body => "401 Unauthorized", :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_app_authentication_to_crowd_fails
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"MyPassword\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'22', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 401, :body => "401 Unauthorized: Application failed to authenticate", :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    user = nil
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    user, message = auth_engine.authenticate

    assert_equal "401 Unauthorized", message
  end

  def test_returns_a_message_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal 'Authentication required', auth_engine.authenticate.last
  end

  def test_returns_nil_when_a_user_cannot_be_found
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"MyPassword\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'22', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => { "name" => "Joe" }.to_json, :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_nil_when_no_password_is_provided
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'12', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 400, :body => "Bad Request", :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_the_user_is_not_found_on_crowd
    user = nil
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"MyPassword\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'22', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 400, :body => "Bad Request", :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)

    user, message = auth_engine.authenticate

    assert_equal "400 Bad Request", message
  end

  def test_returns_a_message_when_no_password_is_provided
    user = nil
    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'12', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 400, :body => "Bad Request", :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)

    user, message = auth_engine.authenticate

    assert_equal "400 Bad Request", message
  end

  def test_returns_a_user
    user = User.create(:login => "Joe", :password => "MyPassword", :password_confirmation => "MyPassword", :email => "joe@example.com")

    stub_request(:post, "http://obs-api:app_password@127.0.0.1/crowd/rest/usermanagement/latest/authentication?username=Joe").
      with(:body => "{\"value\":\"MyPassword\"}",
           :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'22', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => { "name" => "Joe" }.to_json, :headers => {})

    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CrowdEngine.new(@configuration, @environment)
    assert_equal user, auth_engine.authenticate
  end
end