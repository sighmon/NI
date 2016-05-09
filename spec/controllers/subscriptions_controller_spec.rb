require 'rails_helper'

class FakeResponse
  def initialize(result)
    @result = result
  end
  def success?
    return @result
  end
  def params
  	return ["Fake params"]
  end
  def message
  	return "Fake message"
  end
end

class FakeGateway
  def initialize(result)
    @result = result
  end
  def purchase(*bla)
    return FakeResponse.new(@result)
  end
end

describe SubscriptionsController, :type => :controller do

	context "as a user" do

		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in user
		end

		describe "POST create" do

    	context "with valid session" do

    		before(:each) do
					# session[:express_purchase_subscription_duration] = 12
					# session[:express_purchase_price] = 6000
					# session[:express_token] = "xxx"
					# session[:express_payer_id] = user.id
					# session[:express_email] = user.email
					# session[:express_paper] = 0
					# session[:express_autodebit] = false
    		end

      	context "and stubbed success" do

        	it "should create a subscription" do
          	SubscriptionsController::EXPRESS_GATEWAY = FakeGateway.new(true)
          	expect {
            	post :create, {
            		:user_id => user.id, 
            		:valid_from => DateTime.now, 
            		:duration => 12, 
            		:purchase_date => DateTime.now
            	}
          	}.to change(Subscription, :count).by(1)
        	end
      	end

      	context "and stubbed failure" do

        	it "should not create a subscription" do
          	SubscriptionsController::EXPRESS_GATEWAY = FakeGateway.new(false)
          	expect {
            	post :create, {:user_id => user.id}
          	}.to change(Subscription, :count).by(0)
        	end

      	end

    	end

  	end

	end

end
