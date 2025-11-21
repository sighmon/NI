require 'rails_helper'

describe PaymentNotification, type: :model do

	context "with a subscriber" do

		let(:paypal_profile_id) do
			"A1111111"
		end

		let(:payer_id) do
				"ABC123"
			end

		let(:params) do
			{
				"payer_id" => payer_id,
				"payment_status" => "Completed", 
				"txn_id" => "TRANSACTIONID", 
				"txn_type" => "recurring_payment",
				"recurring_payment_id" => paypal_profile_id,
				"profile_status" => "Active"
			}
		end

		let(:user) do
			subscription = FactoryBot.create(:subscription)
			subscription.paypal_profile_id = paypal_profile_id
			subscription.save
			subscription.user
		end

		context "after creating a PaymentNotification" do

			let(:payment_notification) do
				PaymentNotification.create(params: params, user_id: user.id, status: params["payment_status"], transaction_id: params["txn_id"], transaction_type: params["txn_type"])
			end

			it "doesn't save params" do
				reloaded_payment_notification = PaymentNotification.find(payment_notification.id)
				expect(reloaded_payment_notification.params).to be_nil
			end

			it "does save the user_id" do
				u = User.find(payment_notification.user.id)
				expect(u.subscriptions.last.paypal_payer_id).to eq(payer_id)
			end

		end

	end

end
