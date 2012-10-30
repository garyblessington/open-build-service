require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class AuthenticationEngineTest < ActiveSupport::TestCase
  def test_ichain_engine_set_to_on
    config = {
      'ichain_mode' => :on
    }

    environment = {}

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_simulate
    config = {
      'ichain_mode' => :simulate
    }

    environment = {}

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_off
    config = {
      'ichain_mode' => :off
    }

    environment = {}

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_nothing
    config = {
      'ichain_mode' => ''
    }

    environment = {}

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_x_http_authorization_header
    config = {
      'allow_anonymous' => true
    }

    environment = {
      'X-HTTP-Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::HttpBasicEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_authorization_header
    config = {
      'allow_anonymous' => true
    }

    environment = {
      'Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::HttpBasicEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_http_authorization_header
    config = {
      'allow_anonymous' => true
    }

    environment = {
      'HTTP_AUTHORIZATION' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::HttpBasicEngine", auth_engine.engine.class.to_s
  end

  def test_http_basic_engine_http_non_anonymous
    config = {
      'allow_anonymous' => false
    }

    environment = {
      'HTTP_AUTHORIZATION' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_not_equal "Opensuse::Authentication::HttpBasicEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_x_http_authorization_header_ldap_mode_on
    config = {
      'ldap_mode' => :on
    }

    environment = {
      'X-HTTP-Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s

  end

  def test_ldap_engine_authorization_header_ldap_mode_on
    config = {
      'ldap_mode' => :on
    }

    environment = {
      'Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_http_authorization_header_ldap_mode_on
    config = {
      'ldap_mode' => :on
    }

    environment = {
      'HTTP_AUTHORIZATION' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_ldap_mode_off
    config = {
      'ldap_mode' => :off
    }

    environment = {
      'HTTP_AUTHORIZATION' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_not_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_x_http_authorization_header
    config = {}

    environment = {
      'X-HTTP-Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_authorization_header
    config = {}

    environment = {
      'Authorization' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_x_http_authorization_header
    config = {}

    environment = {
      'HTTP_AUTHORIZATION' => 'Joe'
    }

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_no_engine
    config = {}
    environment = {}

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(config, environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end
end