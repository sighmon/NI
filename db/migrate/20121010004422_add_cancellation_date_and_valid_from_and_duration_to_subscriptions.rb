class AddCancellationDateAndValidFromAndDurationToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :cancellation_date, :datetime
    add_column :subscriptions, :valid_from, :datetime
    add_column :subscriptions, :duration, :integer
  end
end
