class Purchases < ActiveRecord::Base
    
    attr_accessible :created_at, :issue_id, :user_id
    belongs_to :issue
    belongs_to :user
end
