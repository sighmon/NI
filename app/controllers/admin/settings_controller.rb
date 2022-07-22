class Admin::SettingsController < Admin::BaseController

  # Cancan authorisation
  # load_and_authorize_resource

  def index
    @settings = Settings.all.select {|x| (not x.var.include?('_csv') and not x.var.include?('_stats'))}
  end

  def update
    setting = Settings.find_by(var: params[:id])
    setting.value = params[:value].to_i
    setting.save
    redirect_to admin_settings_path, notice: 'Setting was successfully updated.'
  end  

end
