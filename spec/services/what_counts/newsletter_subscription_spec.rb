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

  it "subscribes the newsletter signup through the WhatCounts HTTP API" do
    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: 1 record(s) processed.",
      body: "SUCCESS: 1 record(s) processed."
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?r=myRealm&p=secret&c=sub&list_id=13&format=99&data=email%2Ccustom_pref_monthly_edition%5Ejane.doe%40example.com%2C1&override_confirmation=1&force_sub=1",
      hash_including(timeout: 10)
    ).and_return(response)

    result = described_class.new(email: "jane.doe@example.com").call

    expect(result).to be_success
    expect(result.subscribed).to eq(true)
    expect(result.message).to eq("Thanks for signing up to the newsletter.")
  end

  it "treats duplicate subscriptions as a successful signup" do
    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "FAILURE: Cannot insert duplicate subscription",
      body: "FAILURE: Cannot insert duplicate subscription"
    )

    allow(HTTParty).to receive(:get).and_return(response)

    result = described_class.new(email: "reader@example.com").call

    expect(result).to be_success
    expect(result.message).to eq("That email is already subscribed to the newsletter.")
    expect(result.subscribed).to eq(true)
  end

  it "fails fast when the WhatCounts configuration is missing" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_LIST_ID").and_return("")

    expect(HTTParty).not_to receive(:get)

    result = described_class.new(email: "reader@example.com").call

    expect(result).not_to be_success
    expect(result.message).to eq("Newsletter signup is not configured yet.")
  end

  it "preserves a legacy api_web base URL for HTTP API subscriptions" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_BASE_URL").and_return("https://mail.example.com/bin/api_web")

    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: 1 record(s) processed.",
      body: "SUCCESS: 1 record(s) processed."
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?r=myRealm&p=secret&c=sub&list_id=13&format=99&data=email%2Ccustom_pref_monthly_edition%5Ereader%40example.com%2C1&override_confirmation=1&force_sub=1",
      hash_including(timeout: 10)
    ).and_return(response)

    result = described_class.new(email: "reader@example.com").call

    expect(result).to be_success
    expect(result.subscribed).to eq(true)
  end

  it "includes api_client and client_auth in HTTP API calls when configured" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_NAME").and_return("Australia")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_AUTH_CODE").and_return("client-key")

    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: Total Records Processed 1, Total Subscriptions 1, Records Added 1, Records Updated 0, Records Ignored (Optout Error)0, Records Failed Other Error 0",
      body: "SUCCESS: Total Records Processed 1, Total Subscriptions 1, Records Added 1, Records Updated 0, Records Ignored (Optout Error)0, Records Failed Other Error 0"
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?api_client=Australia&client_auth=client-key&r=myRealm&p=secret&c=sub&list_id=13&format=99&data=email%2Ccustom_pref_monthly_edition%5Ereader%40example.com%2C1&override_confirmation=1&force_sub=1",
      hash_including(timeout: 10)
    ).and_return(response)

    result = described_class.new(email: "reader@example.com").call

    expect(result).to be_success
    expect(result.subscribed).to eq(true)
  end

  it "returns the newsletter status from the list lookup" do
    response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: {
        "subscriberId" => 7160984,
        "email" => "reader@example.com",
        "firstName" => "Reader"
      },
      body: '{"subscriberId":7160984,"email":"reader@example.com"}'
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/rest/lists/13/subscribers?email=reader%40example.com",
      hash_including(
        headers: hash_including(
          "Accept" => "application/vnd.whatcounts-v1+json",
          "Content-Type" => "application/json"
        ),
        timeout: 10
      )
    ).and_return(response)

    result = described_class.new(email: "reader@example.com").status

    expect(result).to be_success
    expect(result.subscribed).to eq(true)
    expect(result.message).to eq("Subscribed to the email newsletter.")
  end

  it "deletes the subscription by subscriber id when unsubscribing" do
    lookup_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: {
        "subscriberId" => 7160984,
        "email" => "reader@example.com"
      },
      body: '{"subscriberId":7160984,"email":"reader@example.com"}'
    )
    unsubscribe_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: 1 record(s) processed.",
      body: "SUCCESS: 1 record(s) processed."
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/rest/lists/13/subscribers?email=reader%40example.com",
      hash_including(
        headers: hash_including(
          "Authorization" => "Basic #{Base64.strict_encode64("myRealm:secret")}"
        ),
        timeout: 10
      )
    ).ordered.and_return(lookup_response)
    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?r=myRealm&p=secret&c=unsub&list_id=13&data=email%5Ereader%40example.com",
      hash_including(timeout: 10)
    ).ordered.and_return(unsubscribe_response)

    result = described_class.new(email: "reader@example.com").unsubscribe

    expect(result).to be_success
    expect(result.subscribed).to eq(false)
    expect(result.message).to eq("You have been unsubscribed from the newsletter.")
  end

  it "preserves a legacy api_web base URL when unsubscribing" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_BASE_URL").and_return("https://mail.example.com/bin/api_web")

    lookup_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: {
        "subscriberId" => 7160984,
        "email" => "reader@example.com"
      },
      body: '{"subscriberId":7160984,"email":"reader@example.com"}'
    )
    unsubscribe_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: 1 record(s) processed.",
      body: "SUCCESS: 1 record(s) processed."
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/rest/lists/13/subscribers?email=reader%40example.com",
      hash_including(timeout: 10)
    ).ordered.and_return(lookup_response)
    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?r=myRealm&p=secret&c=unsub&list_id=13&data=email%5Ereader%40example.com",
      hash_including(timeout: 10)
    ).ordered.and_return(unsubscribe_response)

    result = described_class.new(email: "reader@example.com").unsubscribe

    expect(result).to be_success
    expect(result.subscribed).to eq(false)
  end

  it "includes api_client and client_auth when unsubscribing through the HTTP API" do
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_NAME").and_return("Australia")
    allow(ENV).to receive(:[]).with("WHATCOUNTS_API_CLIENT_AUTH_CODE").and_return("client-key")

    lookup_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: {
        "subscriberId" => 7160984,
        "email" => "reader@example.com"
      },
      body: '{"subscriberId":7160984,"email":"reader@example.com"}'
    )
    unsubscribe_response = instance_double(
      HTTParty::Response,
      code: 200,
      parsed_response: "SUCCESS: 1 record(s) processed.",
      body: "SUCCESS: 1 record(s) processed."
    )

    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/rest/lists/13/subscribers?email=reader%40example.com",
      hash_including(timeout: 10)
    ).ordered.and_return(lookup_response)
    expect(HTTParty).to receive(:get).with(
      "https://mail.example.com/bin/api_web?api_client=Australia&client_auth=client-key&r=myRealm&p=secret&c=unsub&list_id=13&data=email%5Ereader%40example.com",
      hash_including(timeout: 10)
    ).ordered.and_return(unsubscribe_response)

    result = described_class.new(email: "reader@example.com").unsubscribe

    expect(result).to be_success
    expect(result.subscribed).to eq(false)
  end
end
