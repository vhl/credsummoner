require 'fileutils'
require 'yaml'

module CredSummoner
  class Config
    attr_accessor :okta_aws_embed_link

    def initialize(okta_aws_embed_link: nil)
      @okta_aws_embed_link = okta_aws_embed_link
    end

    def self.exists?
      File.exists?(config_file)
    end

    def self.load
      if exists?
        yaml = YAML.load(File.read(config_file))
        Config.new(okta_aws_embed_link: yaml['okta_aws_embed_link'])
      else
        raise 'no config file'
      end
    end

    def self.config_dir
      "#{ENV['HOME']}/.config/credsummoner"
    end

    def self.config_file
      "#{config_dir}/config.yml"
    end

    def save
      FileUtils.mkdir_p(Config.config_dir)
      File.open(Config.config_file, 'w', 0600) do |file|
        file.puts(YAML.dump(serialize))
      end
    end

    def serialize
      {
        'okta_aws_embed_link' => okta_aws_embed_link
      }
    end
  end
end
