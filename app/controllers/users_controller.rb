class UsersController < ApplicationController
    # Cancan authorisation
    load_and_authorize_resource

    def show

    end
end
