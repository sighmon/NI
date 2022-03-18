require 'rails_helper'

describe Category, type: :model do

  it "can be added to an article" do
    category = FactoryBot.create(:category)
    article = FactoryBot.create(:article)
    article.categories << category
    expect(category.articles).to eq([article])
  end

  it "can render a short display name" do
    category = FactoryBot.create(:category)
    category.name = '/columns/the-debate/'
    category.save
    expect(category.short_display_name).to eq('The Debate')

    category.name = ''
    category.save
    expect(category.short_display_name).to eq('')
  end

end
