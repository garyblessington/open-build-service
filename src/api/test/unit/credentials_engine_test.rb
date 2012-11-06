require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class CredentialsEngineTest < ActiveSupport::TestCase
  def setup
    @configuration = {}
    @environment = {}
  end

  def test_returns_nil_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::CredentialsEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_no_authorization_is_set
    auth_engine = Opensuse::Authentication::CredentialsEngine.new(@configuration, @environment)
    assert_equal 'Authentication required', auth_engine.authenticate.last
  end

  def test_returns_nil_when_a_user_cannot_be_found
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CredentialsEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_a_user_cannot_be_found
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CredentialsEngine.new(@configuration, @environment)

    user, message = auth_engine.authenticate

    assert_equal "Unknown user '#{auth_engine.user_login}' or invalid password", message
  end

  def test_returns_a_valid_user
    user = User.create(:login => 'Joe', :email => 'joe@example.com', :password => 'MyPassword', :password_confirmation => 'MyPassword')
    @environment['X-HTTP_AUTHORIZATION'] = "Basic #{Base64.encode64('Joe:MyPassword')}"
    auth_engine = Opensuse::Authentication::CredentialsEngine.new(@configuration, @environment)

    assert_equal user, auth_engine.authenticate
  end
end