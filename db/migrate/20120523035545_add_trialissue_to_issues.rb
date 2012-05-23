class AddTrialissueToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :trialissue, :boolean
  end
end
