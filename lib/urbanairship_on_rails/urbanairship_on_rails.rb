

# ############################# this belongs in initializer
# require File.dirname(__FILE__) + '/libs/config'
# UA::Config::app_key      = 'YOUR_APP_KEY'
# UA::Config::app_secret   = 'YOUR_APP_SECRET'
# UA::Config::push_secret  = 'YOUR_PUSH_SECRET' 
# UA::Config::push_host    = 'https://go.urbanairship.com'
# #############################

Dir.glob(File.join(File.dirname(__FILE__), 'app', 'models', 'apn', '*.rb')).sort.each do |f|
  require f
end

%w{ models controllers helpers }.each do |dir| 
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path 
  # puts "Adding #{path}"
  ActiveSupport::Dependencies.load_paths << path 
  ActiveSupport::Dependencies.load_once_paths.delete(path) 
end