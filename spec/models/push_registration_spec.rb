require 'rails_helper'

RSpec.describe PushRegistration, type: :model do
  
  context "after creating a PushRegistration" do

    let(:params) do
      {
        token: "<00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000>",
        device: "ios"
      }
    end

    let(:push_registration) do
      PushRegistration.create(token: params[:token], device: params[:device])
    end

    it "saved the token" do
      reloaded_push_registration = PushRegistration.find(push_registration.id)
      expect(reloaded_push_registration.token).to eq(params[:token])
      # expect().to change(PushRegistration, :count).by(1)
    end

  end

end
