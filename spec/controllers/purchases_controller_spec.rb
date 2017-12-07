require 'rails_helper'

class FakeResponse
  def initialize(result)
    @result = result
  end
  def success?
    return @result
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

describe PurchasesController, :type => :controller do

  context "as a user and with an issue" do

   let(:user) { FactoryBot.create(:user) }
   let(:issue) { FactoryBot.create(:issue) }

   before(:each) do
     sign_in user
   end

   describe "POST create" do

     context "with valid session" do

       before(:each) do
         session[:issue_id_being_purchased] = issue.id
         session[:express_purchase_price] = 7.50
       end

       context "and stubbed success" do

         it "should create a purchase" do
           PurchasesController::EXPRESS_GATEWAY=FakeGateway.new(true)
           expect {
             post :create, params: {:issue_id => issue.id}
           }.to change(Purchase, :count).by(1)
         end
       end

       context "and stubbed failure" do

         it "should not a purchase" do
           PurchasesController::EXPRESS_GATEWAY=FakeGateway.new(false)
           expect {
             post :create, params: {:issue_id => issue.id}
           }.to change(Purchase, :count).by(0)
         end

       end

     end

   end  

  end

end
