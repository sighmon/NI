# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Set the subscription and issue price
Settings.subscription_price = 600
Settings.issue_price = 750

# Pagination settings
Settings.issue_pagination = 18
Settings.article_pagination = 20
Settings.guest_pass_key_length = 16
Settings.category_pagination = 24
Settings.users_pagination = 100

# Setup push notification apps
ApplicationHelper.rpush_register_android_app
ApplicationHelper.rpush_register_ios_app

# TODO: setup the admin user

# Setup an issue.

require_dependency Rails.root.join("app/models/issue.rb").to_s

def strip_path_head(path)
  return path.partition("/")[2].partition("/")[2]
end
#db/seed_data/issue/cover/1/452_cover.jpg
for issue_obj in YAML.load_file(Rails.root.join("db/seed_data/issues.yml"))
  issue = issue_obj.to_hash
  issue["editors_photo"] = File.open(Rails.root.join("db/seed_data/issue/editors_photo/#{issue['id']}/#{issue_obj['editors_photo']}"))
  issue["cover"] = File.open(Rails.root.join("db/seed_data/issue/cover/#{issue['id']}/#{issue_obj['cover']}"))
  issue.delete("id")
  issue.delete("created_at")
  issue.delete("updated_at")
  Issue.create(issue)
end

