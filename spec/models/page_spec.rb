require 'rails_helper'

describe Page, type: :model do
  describe 'validations' do
    it 'is valid with a unique permalink' do
      page = Page.new(permalink: 'about')
      expect(page).to be_valid
    end

    it 'is invalid when permalink is missing' do
      page = Page.new
      expect(page).not_to be_valid
      page.validate
      expect(page.errors[:permalink]).to include("can't be blank")
    end

    it 'is invalid when permalink is not unique' do
      Page.create!(permalink: 'contact')
      dup = Page.new(permalink: 'contact')

      expect(dup).not_to be_valid
      dup.validate
      expect(dup.errors[:permalink]).to include("has already been taken")
    end
  end

  describe '#to_param' do
    it 'returns the permalink' do
      page = Page.new(permalink: 'privacy-policy')
      expect(page.to_param).to eq('privacy-policy')
    end
  end
end
