module Opensuse
  module Authentication
    class CrowdEngine
      include Opensuse::Authentication::Logger
      include Opensuse::Authentication::HttpHeader

      attr_reader :configuration, :environment, :crowd_url
      attr_accessor :user_login

      def initialize(configuration, environment)
        @configuration = configuration
        @environment = environment
        if ApplicationSettings::AuthCrowdServer.get.value && ApplicationSettings::AuthCrowdAppName.get.value && ApplicationSettings::AuthCrowdAppPassword.get.value
          @crowd_url = "http://#{ ApplicationSettings::AuthCrowdAppName.get.value }:#{ ApplicationSettings::AuthCrowdAppPassword.get.value }@#{ ApplicationSettings::AuthCrowdServer.get.value }"
        else
          @crowd_url = nil
        end
      end

      def authenticate
        return [nil, "No Crowd Application Configured"] if @crowd_url.blank?

        authorization = extract_authorization_from_header

        logger.send :debug, "AUTH: #{authorization.inspect}"

        if authorization && authorization[0] == "Basic"
          login, password = Base64.decode64(authorization[1]).split(':', 2)[0..1]

          @user_login = login

          user = nil
          error_message = ""
          crowd_info = nil

          begin
            crowd_info = RestClient.post "#{@crowd_url}/crowd/rest/usermanagement/latest/authentication?username=#{login}", { :value => password }.to_json,
              :content_type => :json, :accept => :json
            crowd_info = JSON.parse(crowd_info)
          rescue RestClient::BadRequest, RestClient::Unauthorized => e
            error_message = e.message
          end

          if crowd_info.present? && crowd_info.keys.include?("name")
            # We've found a Crowd authenticated user - now we find an OBS user database entry
            user = User.find_by_login(login)
          end

          if user
            user
          else
            [nil, error_message ||  "Unknown user '#{login}' or invalid password"]
          end
        else
          logger.send :debug, "No authentication string was sent"
          [nil, "Authentication required"]
        end
      end
    end
  end
end