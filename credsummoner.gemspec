Gem::Specification.new do |s|
  s.name        = 'credsummoner'
  s.version     = '0.1.0'
  s.date        = '2019-07-03'
  s.summary     = 'Retrieve temporary AWS credentials via an identity provider'
  s.description = 'Retrieve temporary AWS credentials via an identity provider.'
  s.authors     = ['David Thompson']
  s.email       = 'dthompson@vistahigherlearning.com'
  s.homepage    = 'https://github.com/vhl/credsummoner'
  s.license     = 'GPL-3.0+'
  s.files       = [
    'lib/credsummoner.rb',
    'lib/credsummoner/account.rb',
    'lib/credsummoner/config.rb',
    'lib/credsummoner/role.rb',
    'lib/credsummoner/saml_assertion.rb',
    'lib/credsummoner/web.rb',
    'lib/credsummoner/okta/credentials.rb',
    'lib/credsummoner/okta/session.rb',
    'lib/credsummoner/okta/user.rb'
  ]
  s.executables = ['credsummoner']
  s.add_dependency 'aws-sdk-core', '~> 3.0'
  s.add_dependency 'nokogiri', '~> 1.0'
  s.add_dependency 'tty-prompt', '~> 0.19'
end
