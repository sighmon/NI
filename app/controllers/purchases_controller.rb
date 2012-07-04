class PurchasesController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to do that."
    end

    def express
        # TODO: have purchase_price stored in the db
        # TODO: add this to routes so we can link to making the purchase
        express_purchase_price = 200
        response = EXPRESS_GATEWAY.setup_purchase(express_purchase_price,
            :ip                => request.remote_ip,
            :return_url        => issue_url(@issue),
            :cancel_return_url => issue_url(@issue)
        )
        redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
    end

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
