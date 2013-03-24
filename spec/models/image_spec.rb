require 'spec_helper'

describe Image do

  context "article" do 

    let(:article) { FactoryGirl.create(:article) }

    it "can create a new image with article.image.create" do
      expect {
        image = article.images.create(data: "notanimage")
        pp image
      }.to change(Image, :count).by(1)
    end

  end
end
