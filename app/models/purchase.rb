class Purchase < ActiveRecord::Base
    
    attr_accessible :user_id, :issue_id, :created_at
    belongs_to :user
    belongs_to :issue
end
