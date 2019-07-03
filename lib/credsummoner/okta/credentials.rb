module CredSummoner
  module Okta
    class Credentials
      attr_reader :password, :totp_token

      def initialize(password, totp_token)
        @password = password
        @totp_token = totp_token
      end
    end
  end
end
