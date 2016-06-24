require 'rails_helper'

RSpec.describe DeviseMailer do
  describe 'reset_password_instructions' do
    let(:user) { FactoryGirl.create(:user) }
    let(:mail) { described_class.reset_password_instructions(user, "faketoken", {}).deliver_now }


    it 'renders the receivers email' do
      expect(mail.to).to eq([user.email])
    end

    it "isn't using the old HTML template" do
      expect(mail.body.encoded).to_not match("EMAIL RESET CODE")
    end

  end
end
