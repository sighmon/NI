class PurchasesController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    def new
        @issue = Issue.find(params[:issue_id])
        @user = User.find(current_user)
        # TODO: How do we create a join, rather than a new issue?
        @purchase = @user.purchases.build(params[:issue])

        respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @purchase }
        end
    end

    def create
        @issue = Issue.find(params[:issue_id])
        @user = User.find(current_user)
        # TODO: How do we create a join, rather than a new issue?
        # @purchase = @user.purchases.create(params[:issue])
        # FIXME: Work out how to simplify this call.
        @purchase = Purchase.create(:user_id => @user.id, :issue_id => @issue.id)

        respond_to do |format|
            if @purchase.save
                format.html { redirect_to issue_path(@issue), notice: 'Issue was successfully purchased.' }
                format.json { render json: @purchase, status: :created, location: @purchase }
            else
                format.html { redirect_to issue_path(@issue), notice: "Couldn't purchase this issue." }
                format.json { render json: @purchase.errors, status: :unprocessable_entity }
            end
        end
    end

end
