require 'rails_helper'

describe Favourite, type: :model do
  describe 'associations' do
    it 'belongs to a user' do
      reflection = Favourite.reflect_on_association(:user)
      expect(reflection.macro).to eq(:belongs_to)
    end

    it 'belongs to an article' do
      reflection = Favourite.reflect_on_association(:article)
      expect(reflection.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'is valid with a user_id and an article_id' do
      favourite = Favourite.new(user_id: 1, article_id: 2)
      expect(favourite).to be_valid
    end

    it 'is invalid without a user_id' do
      favourite = Favourite.new(article_id: 2)

      expect(favourite).not_to be_valid
      favourite.validate
      expect(favourite.errors[:user_id]).to include("can't be blank")
    end

    it 'is invalid without an article_id' do
      favourite = Favourite.new(user_id: 1)

      expect(favourite).not_to be_valid
      favourite.validate
      expect(favourite.errors[:article_id]).to include("can't be blank")
    end
  end
end
