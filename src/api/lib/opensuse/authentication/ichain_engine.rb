module Opensuse
  module Authentication
    class IchainEngine
      include Opensuse::Authentication::Logger

      attr_reader :configuration, :environment
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
      end

      def authenticate
        mode = [configuration['ichain_mode'], configuration['proxy_auth_mode']].compact.uniq.last
        proxy_user = environment['HTTP_X_USERNAME']

        if proxy_user
          logger.send :info, "iChain user extracted from header: #{proxy_user}"
        elsif mode == :simulate
          proxy_user = configuration['proxy_auth_test_user']
          logger.send :debug, "iChain user extracted from config: #{proxy_user}"
        end

        @user_login = proxy_user unless proxy_user.nil?

        # We're using a login proxy, there is no need to authenticate the user from crendentials
        # However we have to care for the status of the user that must not be unconfirmed or proxy requested
        user = nil

        if proxy_user
          user = User.find_by_login proxy_user
        else
          if configuration['allow_anonymous']
            user = User.find_by_login("_nobody_")
          end
        end

        if user
          return user
        else
          logger.send :error, "No HTTP_X_USERNAME header from login proxy! Are we really using an authentication proxy?"
          return [nil, "No user header found!"]
        end
      end
    end
  end
end