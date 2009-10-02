# desc "Explaining what the task does"
# task :urban_airship_on_rails do
#   # Task goes here
# end

namespace :apn do
  desc "retreive and process list of inactive devices"
  task :feedback => [:environment] do
    APN::Feedback.new
  end
end