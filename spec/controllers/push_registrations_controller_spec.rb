require 'rails_helper'

RSpec.describe PushRegistrationsController, type: :controller do

  describe "POST #create" do

    let(:push_registration) { FactoryBot.create(:push_registration) }

    it "saved the token" do
      expect{
        post :create, { token: push_registration.token, device: push_registration.device }
      }.to change(PushRegistration, :count).by(1)
    end

    it "with the same token it updates the modified date" do
      last_updated_date = PushRegistration.find_by_token(push_registration.token).updated_at
      Timecop.freeze(Time.zone.now + 1.day) do
        post :create, { token: push_registration.token, device: push_registration.device }
        expect(PushRegistration.find_by_token(push_registration.token).updated_at).to_not eq(last_updated_date)
      end
    end

  end

  describe "DELETE #destroy" do

    it "can delete a push registration" do
      push_registration = FactoryBot.create(:push_registration)
      expect{
        delete :destroy, { id: push_registration.id }
      }.to change(PushRegistration, :count).by(-1)
    end

  end

end
