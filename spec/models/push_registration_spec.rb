require 'rails_helper'

RSpec.describe PushRegistration, type: :model do
  
  context "after creating a PushRegistration" do

    let(:push_registration) do
      FactoryGirl.create(:push_registration)
    end

    it "saved the token" do
      reloaded_push_registration = PushRegistration.find(push_registration.id)
      expect(reloaded_push_registration.token).to eq(push_registration.token)
      # expect().to change(PushRegistration, :count).by(1)
    end

  end

end
