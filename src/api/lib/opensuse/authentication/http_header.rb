module Opensuse
  module Authentication
    module HttpHeader
      def extract_authorization_from_header
        if environment.has_key? 'X-HTTP_AUTHORIZATION'
          # try to get it where mod_rewrite might have put it
          authorization = environment['X-HTTP_AUTHORIZATION'].to_s.split
        elsif environment.has_key? 'Authorization'
          # for Apace/mod_fastcgi with -pass-header Authorization
          authorization = environment['Authorization'].to_s.split
        elsif environment.has_key? 'HTTP_AUTHORIZATION'
          # this is the regular location
          authorization = environment['HTTP_AUTHORIZATION'].to_s.split
        end
      end
    end
  end
end