desc "This task is called by the Heroku scheduler add-on"
task update_subscriber_stats: :environment do
  puts "Updating subscriber stats..."
  User.update_subscriber_stats
  puts "Finished updating subscriber stats."
end
