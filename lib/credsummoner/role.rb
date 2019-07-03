require 'aws-sdk-core'

class Role
  attr_reader :name, :arn, :principal_arn

  def initialize(name:, arn:, principal_arn:)
    @name = name
    @arn = arn
    @principal_arn = principal_arn
  end

  def assume(saml, duration, region)
    sts = Aws::STS::Client.new(region: region)
    sts.assume_role_with_saml(
      principal_arn: principal_arn,
      role_arn: arn,
      saml_assertion: saml.response,
      duration_seconds: duration
    ).credentials
  end

  def to_s
    name
  end
end
