class Settings < RailsSettings::Base
  scope :application do
    field :admin_alert, type: :boolean
    field :article_pagination, type: :integer
    field :category_pagination, type: :integer
    field :current_digital_subscribers_csv, type: :string
    field :current_paper_subscribers_csv, type: :string
    field :guest_pass_key_length, type: :integer
    field :issue_pagination, type: :integer
    field :issue_price, type: :integer
    field :lapsed_digital_subscribers_csv, type: :string
    field :lapsed_institution_subscribers_csv, type: :string
    field :subscriber_stats, type: :string
    field :subscription_price, type: :integer
    field :uk_export_csv, type: :string
    field :users_csv, type: :string
    field :users_pagination, type: :integer
  end
end
