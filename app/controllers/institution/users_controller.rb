#class Institution::UsersController < ApplicationController
class Institution::UsersController < Institution::BaseController
  # GET /institution/users
  # GET /institution/users.json

  # Cancan authorisation
  load_and_authorize_resource

  def index
    @users = current_user.children
    #@users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /institution/users/1
  # GET /institution/users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /institution/users/new
  # GET /institution/users/new.json
  def new
    #@user = User.new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /institution/users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /institution/users
  # POST /institution/users.json
  def create
    @user = current_user.children.create(user_params.merge :email => "design+parent_id_#{current_user.id}_child_username_#{params["user"].try(:[],"username").try(:downcase).try(:tr," ", "_")}@newint.com.au")

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_path(current_user), notice: 'User was successfully created.' }
        format.json { render json: [:institution, @user], status: :created, location: @user }
      else
        format.html { render action: "new", notice: "Sorry, user couldn't be created. Contact us for help." }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /institution/users/1
  # PUT /institution/users/1.json
  def update
    if params[:user] and params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to user_path(current_user), notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /institution/users/1
  # DELETE /institution/users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to user_path(current_user), notice: 'Student user account was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def user_params
    params.fetch(:user, {}).permit(:issue_ids, :login, :username, :expirydate, :subscriber, :email, :password, :password_confirmation, :remember_me, :uk_id, :uk_expiry, :institution)
  end

end
