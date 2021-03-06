# Represents the message you wish to send. 
# An APN::Notification belongs to an APN::Device.
# 
# Example:
#   apn = APN::Notification.new
#   apn.badge = 5
#   apn.sound = 'my_sound.aiff'
#   apn.alert = 'Hello!'
#   apn.device = APN::Device.find(1)
#   apn.save
# 
# To deliver call the following method:
#   APN::Notification.send_notifications
# 
# As each APN::Notification is sent the <tt>sent_at</tt> column will be timestamped,
# so as to not be sent again.
class APN::Notification < APN::Base
  include AASM
  include ::ActionView::Helpers::TextHelper
  extend ::ActionView::Helpers::TextHelper
  
  belongs_to :device, :class_name => 'APN::Device'

  #
  # MODEL STATE MACHINE
  #
  aasm_initial_state :pending
  aasm_column :state
  
  aasm_state :pending
  aasm_state :processed, :enter => :update_sent_at

  aasm_event :process do
    transitions :from => :pending, :to => :processed
  end
      
  # An HTTP POST to /api/push/ performs a push notification to one or more users. 
  # The payload is in JSON with content-type application/json, with this structure:
  # {
  #     "device_tokens": [
  #         "some device token",
  #         "another device token"
  #     ],
  #     "aliases": [
  #         "user1",
  #         "user2"
  #     ],
  #     "tags": [
  #         "tag1",
  #         "tag2"
  #     ],
  #     "schedule_for": [
  #         "2010-07-27 22:48:00",
  #         "2010-07-28 22:48:00"
  #     ],
  #     "exclude_tokens": [
  #         "device token you want to skip",
  #         "another device token you want to skip"
  #     ],
  #     "aps": {
  #          "badge": 10,
  #          "alert": "Hello from Urban Airship!",
  #          "sound": "cat.caf"
  #     }
  # }
  # The response is an HTTP 200 OK with no content, or an HTTP 400 Bad Request if the structure was invalid.
  # 
  # This POST is authenticated with the Application Key and Push Secret. 
  # It can contain 0 or many device_tokens, 0 or many aliases, and 0 or many tags. 
  # The ‘aps’ payload is in the same format as Apple’s push notification system.
  # 
  # schedule_for is always optional. 
  # If it’s included, we will delay sending the message until the time given. 
  # If schedule_for is not included the message will be delivered immediately. 
  # The time should be ISO 8601 format in UTC. If schedule_for is included, 
  # the response body will be application/json with the following structure:
  def push(options={})
    puts options.inspect
    options = options.merge(:device_tokens=>[self.device.token_for_ua])
    http_post("/api/push/", options, {}, true)
  end
  
  def update_sent_at
    sent_at = Time.now
  end
  
  def self.process_pending    
    self.pending.each do |n|
      puts "process #{n.inspect}"
      n.push({:aps=>{:badge=>n.badge, :alert=>n.alert, :sound=>n.sound}})
      n.process!
    end    
  end
    
end # APN::Notification