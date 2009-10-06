# desc "Explaining what the task does"
# task :urban_airship_on_rails do
#   # Task goes here
# end

namespace :apn do
  desc "retreive and process list of inactive devices"
  task :feedback => [:environment] do
    APN::Feedback.create().run
  end

  desc "retreive and process list of inactive devices"
  task :push => [:environment] do
    APN::Notification.process_pending
  end
end