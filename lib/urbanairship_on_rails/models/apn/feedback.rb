require 'json'
# 
# Apple notifies UA when a notification is sent to a device that has push notifications enabled (for at least one application) 
# but has turned off or uninstalled your application. We immediate stop sending notifications through to avoid angering Apple.
# 
# To query what device tokens are now invalid, do an HTTP GET to /api/device_tokens/feedback/?since=<timestamp> with the push secret; 
# the query argument since is required, and is a timestamp in ISO 8601 format, e.g. /api/device_tokens/feedback/?since=2009-06-01+13:00:00. 
# The return value is application/json with the following structure:
# 
class APN::Feedback < APN::Base
  
  def initialize(options=nil)
    puts "APN::Feedback"
    super(options)
    get_feedback { |results| 
      puts results.inspect
      if results.code.to_i == 200         
        result = JSON.parse(results.body) # parse json results

        result.each do |item| # iterate results and delete devices that have been deactivated
          puts "    search and destroy #{item['device_token']}"      
          d = APN::Device.find_by_token(item['device_token'])
          d.destroy if d
        end   
      end   
    }    
  end
  
  # get_feedback returns json
  def get_feedback
    puts "APN::get_feedback"
    time = 1.day.ago.iso8601
    puts "    since #{time}"
    
    result = http_get("/api/device_tokens/feedback/?since=#{time}", nil, {}, true) 
    self.code = result.code.to_s
    self.message = result.message.to_s
    self.body = result.body.to_s
    
    # result = '[
    #    {
    #        "device_token": "1234123412341234123412341234123412341234123412341234123412341234",
    #        "marked_inactive_on": "2009-06-22 10:05:00"
    #    },
    #    {
    #        "device_token": "ABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCD",
    #        "marked_inactive_on": "2009-06-22 10:07:00"
    #    }
    # ]'  
    
    yield result if block_given?
    
  end
  
end