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
          if [:on, :simulate].include?([configuration['ichain_mode'], configuration['proxy_auth_mode']].compact.uniq.last)
            Opensuse::Authentication::IchainEngine.new(configuration, environment)
          elsif ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) } && configuration['allow_anonymous']
            Opensuse::Authentication::HttpBasicEngine.new(configuration, environment)
          elsif ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) } && configuration['ldap_mode'] == :on
            Opensuse::Authentication::LdapEngine.new(configuration, environment)
          elsif ["X-HTTP-Authorization", "Authorization", "HTTP_AUTHORIZATION"].any? { |header| environment.keys.include?(header) }
            Opensuse::Authentication::CredentialsEngine.new(configuration, environment)
          end
        end
    end
  end
end