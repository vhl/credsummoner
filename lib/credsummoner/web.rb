require 'json'
require 'net/http'

module CredSummoner
  class Web
    def self.get(url, cookie: nil)
      uri = URI.parse(url)
      http = Net::HTTP::new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Cookie'] = cookie if cookie
      http.request(request)
    end

    def self.post_form(url, form_data)
      uri = URI.parse(url)
      http = Net::HTTP::new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(form_data)
      http.request(request)
    end

    def self.post_json(url, args)
      uri = URI.parse(url)
      http = Net::HTTP::new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = args.to_json
      request.content_type = 'application/json'
      response = http.request(request)
      if response.code == '200'
        JSON.parse(response.body)
      else
        false
      end
    end
  end
end
