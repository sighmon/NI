class PurchasesController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    rescue_from CanCan::AccessDenied do |exception|
        session[:user_return_to] = request.referer
        redirect_to new_user_session_path, :alert => "You need to be logged in to do that."
    end

    def express
        # TODO: move the purchase price to an admin model
        @express_purchase_price = 200
        session[:express_purchase_price] = @express_purchase_price
        @issue = Issue.find(params[:issue_id])
        response = EXPRESS_GATEWAY.setup_purchase(@express_purchase_price,
            :ip                 => request.remote_ip,
            :return_url         => new_issue_purchase_url(@issue),
            :cancel_return_url  => new_issue_purchase_url(@issue),
            :allow_note         => true,
            :items              => [{:name => "NI #{@issue.number} - #{@issue.title}", :quantity => 1, :description => "New Internationalist Magazine - digital edition", :amount => @express_purchase_price}],
            :currency           => 'AUD'
        )
        redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
    end

    def retrieve_paypal_express_details(token)
        details = EXPRESS_GATEWAY.details_for(token)
        # logger.info details.params
        session[:express_payer_id] = details.payer_id
        session[:express_email] = details.email
        session[:express_first_name] = details.params["first_name"]
        session[:express_last_name] = details.params["last_name"]
    end

    def new
        @user = User.find(current_user)
        @purchase = @user.purchases.build(params[:issue])
        @express_token = params[:token]
        @express_payer_id = params[:PayerID]

        @has_token = not(@express_token.blank? or @express_payer_id.blank?)

        if @has_token
            @issue = Issue.find(session[:issue_id_being_purchased])
            retrieve_paypal_express_details(@express_token)
            session[:express_token] = @express_token
        else
            @issue = Issue.find(params[:issue_id])
            session[:issue_id_being_purchased] = @issue.id
        end

        respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @purchase }
        end
    end

    def create
        @issue = Issue.find(session[:issue_id_being_purchased])
        @user = User.find(current_user)

        # Make the PayPal purchase
        response = EXPRESS_GATEWAY.purchase(session[:express_purchase_price], express_purchase_options)
        if response.success?
            # FIXME: Work out how to simplify this call.
            @purchase = Purchase.create(:user_id => @user.id, :issue_id => @issue.id)
        end

        respond_to do |format|
            if response.success? and @purchase.save
                # Email the user a confirmation
                UserMailer.issue_purchase(@user, @issue).deliver
                format.html { redirect_to issue_path(@issue), notice: 'Issue was successfully purchased.' }
                format.json { render json: @purchase, status: :created, location: @purchase }
            else
                format.html { redirect_to issue_path(@issue), notice: "Couldn't purchase this issue." }
                format.json { render json: @purchase.errors, status: :unprocessable_entity }
            end
        end
    end

    private

    def express_purchase_options
      {
        :ip         => request.remote_ip,
        :token      => session[:express_token],
        :payer_id   => session[:express_payer_id],
        :items      => [{:name => "NI #{@issue.number} - #{@issue.title}", :quantity => 1, :description => "New Internationalist Magazine - digital edition", :amount => session[:express_purchase_price]}],
        :currency   => 'AUD'
      }
    end

end
