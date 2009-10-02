module UA
  
  module Config
    
    @@app_key = 'YOUR_APP_KEY'
    @@app_secret = 'YOUR_APP_SECRET'
    @@push_secret = 'YOUR_PUSH_SECRET'
    @@push_host = 'go.urbanairship.com'
    @@push_port = 443

    [:app_key, :app_secret, :push_secret, :push_host, :push_port].each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__
        def self.#{sym}
          if defined?(#{sym.to_s.upcase})
            #{sym.to_s.upcase}
          else
            @@#{sym}
          end
        end
        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
     EOS

    end
    
  end # Config
   
end # UA
