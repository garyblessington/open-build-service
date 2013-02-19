require File.expand_path(File.dirname(__FILE__) + "/..") + "/test_helper"

class AuthenticationEngineTest < ActiveSupport::TestCase
  def setup
    @config = {}
    @environment = {}
  end

  def test_ichain_engine_set_to_on
    @config['ichain_mode'] = :on
    ApplicationSettings::AuthIchainMode.set!('on')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_simulate
    @config['ichain_mode'] = :simulate
    ApplicationSettings::AuthIchainMode.set!('simulate')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::IchainEngine", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_off
    @config['ichain_mode'] = :off
    ApplicationSettings::AuthIchainMode.set!('off')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_ichain_engine_set_to_nothing
    @config['ichain_mode'] = ''
    ApplicationSettings::AuthIchainMode.set!('')

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_x_http_authorization_header
    @environment['X-HTTP-Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_authorization_header
    @environment['Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_credentials_engine_http_authorization_header
    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::CredentialsEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_x_http_authorization_header_ldap_mode_on
    ApplicationSettings::LdapMode.set!(true)

    @environment['X-HTTP-Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_authorization_header_ldap_mode_on
    ApplicationSettings::LdapMode.set!(true)

    @environment['Authorization'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_http_authorization_header_ldap_mode_on
    ApplicationSettings::LdapMode.set!(true)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_ldap_engine_ldap_mode_off
    ApplicationSettings::LdapMode.set!(false)

    @environment['HTTP_AUTHORIZATION'] = 'Joe'

    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_not_equal "Opensuse::Authentication::LdapEngine", auth_engine.engine.class.to_s
  end

  def test_no_engine
    auth_engine = Opensuse::Authentication::AuthenticationEngine.new(@config, @environment)
    assert_equal "NilClass", auth_engine.engine.class.to_s
  end
end