class Purchases < ActiveRecord::Base
    belongs_to :issue
    belongs_to :user
    attr_accessible :created_at, :issue_id, :user_id
end
