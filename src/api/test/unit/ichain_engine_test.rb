require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class IchainEngineTest < ActiveSupport::TestCase
  def setup
    @configuration = {}
    @environment = {}
  end

  def test_returns_nil_when_the_http_x_user_name_header_is_empty
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)

    assert_equal nil, auth_engine.authenticate.first
  end

  def test_sets_the_user_login_to_the_http_x_user_name
    @environment['HTTP_X_USERNAME'] = 'Joe'
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)
    auth_engine.authenticate

    assert_equal 'Joe', auth_engine.user_login
  end

  def test_returns_a_user_from_the_database
    user = User.create(:login => "Joe", :password => "mypassword", :password_confirmation => "mypassword", :email => "joe@example.com")

    @environment['HTTP_X_USERNAME'] = 'Joe'
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)
    assert_equal user, auth_engine.authenticate
  end

  def test_returns_a_nobody_user_if_allow_anonymous_is_set_and_no_proxy_user_is_defined
    user = User.find_by_login("_nobody_")

    @configuration['allow_anonymous'] = true
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)
    assert_equal user, auth_engine.authenticate
  end

  def test_returns_nil_when_a_user_is_not_found_in_the_database
    @environment['HTTP_X_USERNAME'] = 'Joe'
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)
    assert_equal nil, auth_engine.authenticate.first
  end

  def test_returns_a_message_when_a_user_is_not_found
    @environment['HTTP_X_USERNAME'] = 'Joe'
    auth_engine = Opensuse::Authentication::IchainEngine.new(@configuration, @environment)
    assert_equal 'No user header found!', auth_engine.authenticate.last
  end
end