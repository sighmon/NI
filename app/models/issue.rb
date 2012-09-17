class Issue < ActiveRecord::Base
  attr_accessible :number, :release, :title, :trialissue, :cover, :editors_letter, :editors_name, :editors_photo
  has_many :articles
  has_many :purchases
  has_many :users, :through => :purchases
  mount_uploader :cover, CoverUploader
  mount_uploader :editors_photo, EditorsPhotoUploader
  # If versions need reprocssing
  # after_update :reprocess_image

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def self.search(params)
    tire.search(load: true) do
      query { string params[:query]} if params[:query].present?
    end
  end

  private

  def reprocess_image
    cover.recreate_versions!
    editors_photo.recreate_versions!
  end

end
