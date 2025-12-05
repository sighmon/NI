class GuestPass < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :article

  before_create :generate_key

  validates_presence_of :user_id
  validates_presence_of :article_id
  validates_uniqueness_of :key

  protected 

  def generate_key
    attempts_remaining = 100  
    begin
     
      key = SecureRandom.urlsafe_base64(Settings.guest_pass_key_length)

      return false if (attempts_remaining-=1)<=0

    end while GuestPass.where(key: key).exists?
    self.key = key
  end

end
