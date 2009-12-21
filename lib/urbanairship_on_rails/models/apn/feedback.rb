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
  include AASM

  #
  # MODEL STATE MACHINE
  #
  aasm_initial_state :pending
  aasm_column :state

  aasm_state :pending
  aasm_state :active
  aasm_state :processed

  aasm_event :pend do
    transitions :from => [:active, :processed], :to => :pending
  end
  
  aasm_event :activate  do
    transitions :from => [:pending, :processed], :to => :active
  end

  aasm_event :process do
    transitions :from => :active, :to => :processed
  end
    
  def run
    raise "save feedback record before running" if self.new_record?
    get_feedback { |results| 
      puts results.inspect
      if results.code.to_i == 200         
        result = JSON.parse(results.body) # parse json results

        result.each do |item| # iterate results and delete devices that have been deactivated
          # puts "    search and destroy #{item['device_token']}"      
          d = APN::Device.find_by_token(item['device_token'])
          d.destroy if d
        end
        
        self.process!
      end   
    }        
  end
  def get_feedback
    self.activate!
    # puts "APN::get_feedback"
    time = 1.day.ago.iso8601
    # puts "    since #{time}"
    
    result = http_get("/api/device_tokens/feedback/?since=#{time}", nil, {}, true) 

    self.code = result.code.to_s
    self.message = result.message.to_s
    self.body = result.body.to_s
        
    yield result if block_given?
    
  end
  
end