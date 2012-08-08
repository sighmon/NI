Given /^(?:|I )am on the home page$/ do 
  visit root_path
end

Then /^(?:|I )should see "([^\"]*)"$/ do |text|
  page.should have_content text 
end
