require 'fileutils'

module CredSummoner
  module Okta
    class Session
      attr_reader :username, :get_creds

      def initialize(username, get_creds)
        @username = username
        @get_creds = get_creds
      end

      def cache_dir
        "#{ENV['HOME']}/.cache/credsummoner"
      end

      def cache_file
        "#{cache_dir}/okta_session_#{username}"
      end

      def lookup_cached_session
        File.exists?(cache_file) && JSON.parse(File.read(cache_file))
      end

      def cache_session(session)
        FileUtils.mkdir_p(cache_dir)
        File.open(cache_file, 'w', 0600) do |file|
          file.puts(session.to_json)
        end
      end

      def clear!
        File.delete(cache_file)
        @data = nil
      end

      def aws_embed_uri
        @aws_embed_uri ||= URI.parse(Config.load.okta_aws_embed_link)
      end

      def base_okta_url
        "#{aws_embed_uri.scheme}://#{aws_embed_uri.host}"
      end

      def auth_url
        "#{base_okta_url}/api/v1/authn"
      end

      def login(creds)
        response = Web.post_json(auth_url,
                                 username: username,
                                 password: creds.password)

        if response
          status = response['status']
          case status
          when 'SUCCESS'
            response['sessionToken']
          when 'MFA_REQUIRED'
            # FIXME: TOTP is the only supported factor currently.
            factor = response['_embedded']['factors'].find do |factor|
              factor['factorType'] == 'token:software:totp'
            end
            mfa(factor['id'], response['stateToken'], creds)
          end
        else
          raise 'incorrect password'
        end
      end

      def mfa(factor_id, state_token, creds)
        response = Web.post_json("#{base_okta_url}/api/v1/authn/factors/#{factor_id}/verify",
                                 stateToken: state_token,
                                 passCode: creds.totp_token)
        if response
          response['sessionToken']
        else
          raise 'invalid MFA token'
        end
      end

      def create_fresh_session
        creds = get_creds.call
        session_token = login(creds)
        app_url_with_token = "#{aws_embed_uri.to_s}?onetimetoken=#{session_token}"
        # A successful login yields a URL to redirect to and a cookie that has
        # our session.
        response = Web.get(app_url_with_token)
        redirect_url = response['location']
        # Really simple cookie parsing.
        cookie = response.get_fields('set-cookie').map do |field|
          field.split('; ')[0]
        end.join('; ')
        saml_url = Web.get(redirect_url, cookie: cookie)['location']
        data = {
          'saml_url' => saml_url,
          'cookie' => cookie
        }
        cache_session(data)
        data
      end

      def data
        @data ||= lookup_cached_session || create_fresh_session
      end

      def saml_url
        data['saml_url']
      end

      def cookie
        data['cookie']
      end
    end
  end
end
