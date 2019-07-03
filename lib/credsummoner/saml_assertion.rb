require 'base64'
require 'nokogiri'

module CredSummoner
  class SAMLAssertion
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def xml_tree
      @xml_tree ||= Nokogiri::XML(Base64.decode64(response))
    end

    # Role->Principal mapping
    def principal_arn_map
      @principal_arn_map ||=
        begin
          # The SAML document has the principal ARNs and role ARNs in
          # "principal,role" pairs.  So, we generate a mapping from role
          # to principal for lookup later when we talk to AWS STS to
          # create a session.
          saml_xpath = "//saml2:Attribute[@Name='https://aws.amazon.com/SAML/Attributes/Role']/saml2:AttributeValue"
          saml_namespace = 'urn:oasis:names:tc:SAML:2.0:assertion'
          xml_tree.xpath(saml_xpath, saml2: saml_namespace).map do |node|
            node.text.split(',').reverse
          end.to_h
        end
    end
  end
end
