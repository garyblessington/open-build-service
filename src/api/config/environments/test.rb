# Settings specified here will take precedence over those in config/environment.rb

OBSApi::Application.configure do

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils    = true

  # Show full error reports and disable caching
  # local requests don't trigger the global exception handler -> set to false
  config.consider_all_requests_local = false
  config.action_controller.perform_caching             = false

  # Tell ActionMailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.active_record.mass_assignment_sanitizer = :strict

  config.cache_store = :memory_store

  config.active_support.deprecation = :log

end

# Look for a YAML file with test details that will allow people to run tests with different configurations
# for their OBS server backend
if File.exist?("#{ Rails.root }/config/source.yml")
  source_config = YAML.load("#{ Rails.root }/config/source.yml")
  CONFIG['source_host'] = source_config["source_host"]
  CONFIG['source_port'] = source_config["source_port"]
else
  CONFIG['source_host'] = "localhost"
  CONFIG['source_port'] = 3200
end

CONFIG['proxy_auth_mode']=:off
CONFIG['download_url'] = 'http://example.com/download'

CONFIG['response_schema_validation'] = true

# the default is not to write through, only once the backend started
# we set this to true
CONFIG['global_write_through'] = false

# make sure we have invalid setup for errbit
CONFIG['errbit_api_key'] = 'INVALID'
CONFIG['errbit_host'] = '192.0.2.0'

