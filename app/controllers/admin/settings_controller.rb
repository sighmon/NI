class Admin::SettingsController < Admin::BaseController

  # Cancan authorisation
  # load_and_authorize_resource

  def index
  	@settings = Settings.all.select {|x| x.var != 'users_csv'}
  end

  def update
  	Settings[params[:id]] = params[:value].to_i
  	redirect_to admin_settings_path, notice: 'Setting was successfully updated.'
  end  

end
