require 'rails_helper'

describe Purchase, type: :model do
  describe 'associations' do
    it 'belongs to a user' do
      reflection = Purchase.reflect_on_association(:user)
      expect(reflection.macro).to eq(:belongs_to)
    end

    it 'belongs to an issue' do
      reflection = Purchase.reflect_on_association(:issue)
      expect(reflection.macro).to eq(:belongs_to)
    end
  end

  describe 'basic validity' do
    it 'is valid with user_id and issue_id' do
      purchase = Purchase.new(user_id: 1, issue_id: 2)
      expect(purchase).to be_valid
    end

    it 'is valid without user_id or issue_id because no validations exist' do
      purchase = Purchase.new
      expect(purchase).to be_valid
    end
  end
end
