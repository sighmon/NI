require "rails_helper"

describe NewslettersController, type: :routing do
  it "routes GET /newsletter to show" do
    expect(get: "/newsletter").to route_to("newsletters#show")
  end

  it "routes POST /newsletter to create" do
    expect(post: "/newsletter").to route_to("newsletters#create")
  end
end
