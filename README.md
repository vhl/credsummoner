CredSummoner
============

CredSummoner is a tool that developers can use to generate temporary
AWS credentials.  It works by integrating with your identity provider
for user authentication and AWS role access. As of now, the only
supported identity provider is Okta.

## Usage

First, CredSummoner must be configured to use the proper Okta embed
link for AWS access:

```
credsummoner config okta_aws_embed_link https://example.okta.com/home/amazon_aws/xxxxxxxxxxxxxxxxxxxx/999
```

Once configured, `credsummoner get` may be used like so:

```
credsummoner get your-okta-username
```

CredSummoner will prompt for a password and TOTP token.  Upon
successful authentication, CredSummoner will prompt for the AWS
account and IAM role to assume.  A new shell process is then created
with the following environment variables configured with a fresh set
of temporary AWS credentials:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN
```

There are several other ways to invoke `credsummoner get`.  For
example, if you know the AWS account alias and IAM role name, you can
skip the prompts like so:

```
credsummoner get your-okta-username --account=foo --role=Developer
```

You can also tell CredSummoner to spawn an arbitrary program rather
than a shell:

```
credsummoner get your-okta-username -- rails server
```

Or, you can skip spawning another program altogether and just print
out environment variables for easy copy/pasting elsewhere:

```
credsummoner get your-okta-username --env
```

By default, CredSummoner tries to generate credentials that are valid
for 12 hours, the maximum currently allowed by AWS STS.  If an IAM
role has a lower maximum session duration, then the `--duration` flag
must be used to set the desired session duration (in seconds) without
exceeding the limit.

## Installation

CredSummoner is a Ruby gem, and thus can be easily installed with the
`gem` program:

```
gem install credsummoner
```
