require "rails_helper"

describe UserNewsletterSubscriptionsController, type: :routing do
  it "routes GET /users/:user_id/newsletter_subscription to show" do
    expect(get: "/users/1/newsletter_subscription").to route_to(
      "user_newsletter_subscriptions#show",
      user_id: "1"
    )
  end

  it "routes POST /users/:user_id/newsletter_subscription to create" do
    expect(post: "/users/1/newsletter_subscription").to route_to(
      "user_newsletter_subscriptions#create",
      user_id: "1"
    )
  end

  it "routes DELETE /users/:user_id/newsletter_subscription to destroy" do
    expect(delete: "/users/1/newsletter_subscription").to route_to(
      "user_newsletter_subscriptions#destroy",
      user_id: "1"
    )
  end
end
