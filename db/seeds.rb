# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Set the subscription and issue price
Settings.subscription_price = 100
Settings.issue_price = 200

# Pagination settings
Settings.issue_pagination = 12
Settings.article_pagination = 10

# TODO: setup the admin user

# Setup an issue.

Issue.new("issue"=>{"title"=>"Title", "number"=>"1234", "editors_name"=>"Editor Name", 
	"editors_photo"=>File.open(Rails.root.join("public/uploads/issue/editors_photo/34/thumb_thumb_default_editors_photo.jpg")), 
	"editors_letter"=>"Editor's Letter", 
	"cover"=>File.open(Rails.root.join("public/uploads/issue/cover/34/thumb_thumb_default_cover.jpg")), 
	"release(1i)"=>"2012", "release(2i)"=>"12", "release(3i)"=>"1", "release(4i)"=>"00", "release(5i)"=>"00", "trialissue"=>"0"})