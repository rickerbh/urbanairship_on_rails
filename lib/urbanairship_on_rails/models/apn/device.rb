# Represents an iPhone (or other APN enabled device).
# An APN::Device can have many APN::Notification.
# 
# In order for the APN::Feedback system to work properly you *MUST*
# touch the <tt>last_registered_at</tt> column everytime someone opens
# your application. If you do not, then it is possible, and probably likely,
# that their device will be removed and will no longer receive notifications.
# 
# Example:
#   Device.create(:token => '5gxadhy6 6zmtxfl6 5zpbcxmw ez3w7ksf qscpr55t trknkzap 7yyt45sc g6jrw7qz')
class APN::Device < APN::Base
  
  belongs_to :user
  has_many :notifications, :class_name => 'APN::Notification'

  validates_presence_of :token
  validates_uniqueness_of :token
  validates_format_of :token, :with => /^[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}\s[a-z0-9]{8}$/
  
  before_save :set_last_registered_at
  
  # The <tt>feedback_at</tt> accessor is set when the 
  # device is marked as potentially disconnected from your
  # application by Apple.
  attr_accessor :feedback_at
  
  # Stores the token (Apple's device ID) of the iPhone (device).
  # 
  # If the token comes in like this:
  #  '<5gxadhy6 6zmtxfl6 5zpbcxmw ez3w7ksf qscpr55t trknkzap 7yyt45sc g6jrw7qz>'
  # Then the '<' and '>' will be stripped off.
  def token=(token)
    res = token.scan(/\<(.+)\>/).first
    unless res.nil? || res.empty?
      token = res.first
    end
    write_attribute('token', token)
  end

  # sends message to UA to register the device
  # 
  # HTTP PUT to /api/device_tokens/<device_token> registers a device token on our end. 
  # This is necessary for broadcasts, and recommended, but optional for individual pushes. 
  # This returns HTTP 201 Created for first registrations and 200 OK for any updates.
  # 
  # Why use the registration call? We query Apple’s feedback service for you, marking any device tokens 
  # they tell us as inactive so that you don’t accidentally send anything to them any more. 
  # The registration call tells us that the device token is valid as of this time, 
  # so if a user turns push notifications back on for your application they can receive them successfully again.
  # 
  # Use the Application Key and Application Secret to authenticate these requests.
  # 
  # Device tokens should be 64 characters string, uppercase, and not include any spaces. An example device token is:
  # 
  #     FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660
  # 
  # Optionally, include a JSON payload to specify an alias or tags for this device token:
  # 
  # { "alias": "your_user_id", "tags": ["tag1","tag2"]}  
  # 
  # A PUT without an alias will remove any associated alias if the device token already exists. 
  # A PUT with an empty tag list will remove any associated tags.
  def register(tag_array=nil)
    puts "APN::Device.register"
    payload = {:alias => self.user.id}
    payload = {:tags => tag_array}.merge(payload) if tag_array
    http_put("/api/device_tokens/#{self.token}", payload.to_json)
  end
  
  # You can read a device token’s alias with an HTTP GET to /api/device_tokens/<device_token>, which returns application/json:
  # 
  # {"device_token": "some device token","alias": "your_user_id"}
  def read
    http_get("/api/device_tokens/#{self.token}")
  end
  
  # An HTTP DELETE to /api/device_tokens/<device_token> will mark the device token as inactive; 
  # no notifications will be delivered to it until a PUT is executed again. 
  # The DELETE returns HTTP 204 No Content, and needs no payload.
  # 
  # When a token is DELETEd in this manner, any alias or tags will be cleared.
  def unregister
    http_delete("/api/device_tokens/#{token}")
  end
  
  before_destroy :unregister  
  
  private

  def set_last_registered_at
    self.last_registered_at = Time.now if self.last_registered_at.nil?
  end
  
end