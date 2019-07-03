require 'fileutils'
require 'json'
require 'nokogiri'

module CredSummoner
  module Okta
    class User
      attr_reader :username

      def initialize(username, &blk)
        @username = username
        @get_creds = blk.to_proc
      end

      def session
        @session ||= Session.new(username, @get_creds)
      end

      def saml_assertion
        @saml_assertion ||=
          begin
            response = nil
            while true
              # Get the base64 encoded SAML assertion that we will need to
              # send along to AWS.
              response = Web.get(session.saml_url, cookie: session.cookie)
              if response.code == '200'
                break
              else
                # Cookie expired!  Clear session and try again.  The
                # user will be prompted for credentials again.
                session.clear!
              end
            end
            saml_page = response.body
            SAMLAssertion.new(Nokogiri::HTML(saml_page).at_css('form input[name=SAMLResponse]')['value'])
          end
      end

      def role_map
        @role_map ||=
          begin
            # Two things can happen on this sign-in page:
            #
            # 1) The user only has access to a single role in a single
            # account, in which case they are redirected straight to the
            # console for that account + role
            #
            # 2) The user has access to more than one role in one or more
            # accounts, in which case they are presented with a page that
            # lists all accounts and roles for them to choose from.
            #
            # For case #1, the response body will be the empty string and
            # the set-cookie header will contain the account + role
            # information and we will parse that.
            #
            # For case #2, the response body will be scraped for all the
            # account + role information.
            #
            # In both cases we return a hash table mapping accounts to
            # roles.
            response = Web.post_form('https://signin.aws.amazon.com/saml',
                                     SAMLResponse: saml_assertion.response,
                                     RelayState: '')
            if response.body.empty?
              cookie = response.get_fields('set-cookie').each_with_object({}) do |field, h|
                key, value = field.split('; ')[0].split('=')
                h[key] = value
              end
              user_info = JSON.parse(URI.unescape(cookie['aws-userInfo']))
              split_arn = user_info['arn'].split('/')
              role_name = split_arn[1]
              account_id = split_arn[0].split(':')[4]
              role_arn = "arn:aws:iam::#{account_id}:role/#{role_name}"
              account = Account.new(user_info['alias'], account_id)
              role = Role.new(
                name: role_name,
                arn: role_arn,
                principal_arn: saml_assertion.principal_arn_map[role_arn]
              )
              { account => [role] }
            else
              # Time for a little web scraping.  Create an account -> roles mapping
              # so that we can present the user with a list of roles to choose from.
              role_page = response.body
              html = Nokogiri::HTML(role_page)
              accounts = html.css('div[class=saml-account-name]').map do |node|
                # example account text we are parsing:
                #    Account: maestro-staging (774082247212)
                parts = node.text.split(' ')
                name = parts[1]
                id = parts[2][1..-2] # account name is in parens, trim those off
                Account.new(name, id)
              end
              roles = html.css('div[class=saml-account] div[class=saml-account]').map do |node|
                node.css('input[name=roleIndex]').map do |field|
                  id = field['id']
                  arn = field['value']
                  # Extract the human readable role name.
                  name = node.css("label[for='#{id}']").text
                  Role.new(name: name, arn: arn,
                           principal_arn: saml_assertion.principal_arn_map[arn])
                end
              end
              accounts.zip(roles).to_h
            end
          end
      end

      def assume_role(role, duration, region)
        role.assume(saml_assertion, duration, region)
      end
    end
  end
end
