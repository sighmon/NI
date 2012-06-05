class PurchasesController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    def new
        @issue = Issue.find(params[:issue_id])
        @user = User.find(current_user)
        # TODO: How do we create a join, rather than a new issue?
        @purchase = @user.issues.build

        respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @purchase }
        end
  end

    def create
        @issue = Issue.find(params[:issue_id])
        @user = User.find(current_user)
        # TODO: How do we create a join, rather than a new issue?
        @purchase = @user.issues.create(params[:purchase])

        respond_to do |format|
            if @purchase.save
                format.html { redirect_to issue_path(@issue), notice: 'Issue was successfully purchased.' }
                format.json { render json: @purchase, status: :created, location: @purchase }
            else
                format.html { render action: "new" }
                format.json { render json: @purchase.errors, status: :unprocessable_entity }
            end
        end
  end

end
