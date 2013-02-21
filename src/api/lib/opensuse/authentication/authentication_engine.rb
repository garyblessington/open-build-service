module Opensuse
  module Authentication
    class AuthenticationEngine
      attr_reader :configuration, :environment, :engine

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
        @engine = determine_engine
      end

      def authenticate
        if engine.respond_to?(:authenticate)
          engine.authenticate
        else
          raise "Engine #{engine.class.to_s} does not respond to authenticate method"
        end
      end

      private
        def determine_engine
          if ApplicationSettings::AuthCrowdMode.get.value.present? && ApplicationSettings::AuthCrowdServer.get.value.present? && ApplicationSettings::AuthCrowdAppName.get.value && ApplicationSettings::AuthCrowdAppPassword.get.value.present? &&
            environment_contains_valid_headers?
            Opensuse::Authentication::CrowdEngine.new(configuration, environment)
          elsif [:on, :simulate, 'on', 'simulate'].include?([ApplicationSettings::AuthIchainMode.get.value, configuration['proxy_auth_mode']].compact.uniq.last)
            Opensuse::Authentication::IchainEngine.new(configuration, environment)
          elsif ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) } && ApplicationSettings::LdapMode.get.value == true
            Opensuse::Authentication::LdapEngine.new(configuration, environment)
          elsif ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) }
            Opensuse::Authentication::CredentialsEngine.new(configuration, environment)
          elsif configuration['allow_anonymous']
            Opensuse::Authentication::AnonymousEngine.new(configuration, environment)
          end
        end
    end
  end
end