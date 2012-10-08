class Admin::SettingsController < Admin::BaseController

  # Cancan authorisation
  # load_and_authorize_resource

  def index
  	@settings = Settings.all
  end

  def update
  	Settings[params[:id]] = params[:value]
  	redirect_to admin_settings_path, notice: 'Settings were successfully updated.'
  end  

end
