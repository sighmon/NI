require "rails_helper"

describe WhatCounts::NewsletterSubscription do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("WHATCOUNTS_BASE_URL").and_return("https://mail.example.com")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_REALM_NAME").and_return("myRealm")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_PASSWORD").and_return("secret")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_LIST_ID").and_return("13")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_CUSTOMER_KEY").and_return("")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_NAME").and_return("")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_AUTH_CODE").and_return("")
  end

  it "posts the newsletter signup to the WhatCounts list endpoint" do
    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: { "subscriptionId" => 120002 },
      body: '{"subscriptionId":120002}'
    )

    expect(HTTParty).to receive(:post).with(
      "https://mail.example.com/rest/lists/13?format=2&duplicates=0",
      hash_including(
        headers: hash_including(
          "Accept" => "application/vnd.whatcounts-v1+json",
          "Content-Type" => "application/json",
          "Authorization" => "Basic #{Base64.strict_encode64("myRealm:secret")}"
        ),
        body: {
          subscriberId: 0,
          email: "jane.doe@example.com",
          firstName: "Jane Doe"
        }.to_json,
        timeout: 10
      )
    ).and_return(response)

    result = described_class.new(email: "jane.doe@example.com").call

    expect(result).to be_success
    expect(result.message).to eq("Thanks for signing up to the newsletter.")
  end

  it "treats duplicate subscriptions as a successful signup" do
    response = instance_double(
      HTTParty::Response,
      code: 500,
      parsed_response: { "error" => "Cannot insert duplicate subscription" },
      body: '{"error":"Cannot insert duplicate subscription"}'
    )

    allow(HTTParty).to receive(:post).and_return(response)

    result = described_class.new(email: "reader@example.com").call

    expect(result).to be_success
    expect(result.message).to eq("That email is already subscribed to the newsletter.")
  end

  it "fails fast when the WhatCounts configuration is missing" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_LIST_ID").and_return("")

    expect(HTTParty).not_to receive(:post)

    result = described_class.new(email: "reader@example.com").call

    expect(result).not_to be_success
    expect(result.message).to eq("Newsletter signup is not configured yet.")
  end
end
