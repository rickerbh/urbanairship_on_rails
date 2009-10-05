require 'net/http'
require 'net/https'

module APN

  class ConnectionError < StandardError
  end
  
  class RetriableConnectionError < ConnectionError
  end

  class Base < ActiveRecord::Base # :nodoc:

    MAX_RETRIES = 3
    OPEN_TIMEOUT = 60
    READ_TIMEOUT = 60
    
    def self.table_name # :nodoc:
      self.to_s.gsub("::", "_").tableize
    end
        
    def http_get(url, data=nil, headers={}, push=false)
      puts "APN::Base.http_get"
      http_request(:get, url, data, headers, push)
    end
    
    def http_post(url, data=nil, headers={}, push=false)
      puts "APN::Base.http_post"
      http_request(:post, url, data, headers, push)
    end
    
    def http_put(url, data=nil, headers={}, push=false)
      puts "APN::Base.http_put"
      http_request(:put, url, data, headers, push)
    end
    
    def http_delete(url, data=nil, headers={}, push=false)
      puts "APN::Base.http_delete"
      http_request(:delete, url, data, headers, push)      
    end

    private

    def self.open_timeout
      OPEN_TIMEOUT
    end
    
    def self.read_timeout
      READ_TIMEOUT
    end
    
    def retry_exceptions
      retries = MAX_RETRIES
      begin
        yield
      rescue RetriableConnectionError => e
        puts e
        retries -= 1
        retry unless retries.zero?
        raise ConnectionError, e.message
      rescue ConnectionError
        puts e
        retries -= 1
        retry if retry_safe && !retries.zero?
        raise
      end
    end

    def http_request(method, url, data=nil, headers={}, push=false)
      puts "APN::Base.http_request(#{method.inspect}, #{url.inspect}, #{data.inspect}, #{push.inspect})"

      headers['Content-Type'] = 'application/json'

      case method
      when :get
        req = Net::HTTP::Get.new(url, headers)
      when :put
        req = Net::HTTP::Put.new(url, headers)
      when :post
        req = Net::HTTP::Post.new(url, headers)
      when :delete
        req = Net::HTTP::Delete.new(url, headers)
      end
      
      if push
        req.basic_auth(UA::Config::app_key, UA::Config::push_secret)
      else
        req.basic_auth(UA::Config::app_key, UA::Config::app_secret)
      end
      
      puts "auth #{UA::Config::app_key}:#{UA::Config::app_secret}"

      req.body = data.to_json if data
      puts "body #{req.body}"
      
      puts "#{UA::Config::push_host}:#{UA::Config::push_port}"
      http = Net::HTTP.new(UA::Config::push_host, UA::Config::push_port)
      http.use_ssl = true

      http.start {|it|
        retry_exceptions do 
          begin
            response = it.request(req)
            puts "\nResponse #{response.code} #{response.message}:#{response.body}"
            response
          rescue EOFError => e
            raise ConnectionError, "The remote server dropped the connection"
          rescue Errno::ECONNRESET => e
            raise ConnectionError, "The remote server reset the connection"
          rescue Errno::ECONNREFUSED => e
            raise RetriableConnectionError, "The remote server refused the connection"
          rescue Timeout::Error, Errno::ETIMEDOUT => e
            raise ConnectionError, "The connection to the remote server timed out"
          end          
        end
      }      
    end

  end
end