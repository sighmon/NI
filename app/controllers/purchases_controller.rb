class PurchasesController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    def new

        respond_to do |format|
            format.html # new.html.erb
            format.json { render json: @purchase }
        end

  end

    def create

        respond_to do |format|
            if @purchase.save
                format.html { redirect_to @purchase, notice: 'Issue was successfully purchased.' }
                format.json { render json: @purchase, status: :created, location: @purchase }
            else
                format.html { render action: "new" }
                format.json { render json: @purchase.errors, status: :unprocessable_entity }
            end
        end
  end

end
