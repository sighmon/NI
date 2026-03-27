require "rails_helper"

describe "Newsletters", type: :request do
  describe "GET /newsletter" do
    it "renders the signup page" do
      get newsletter_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Newsletter sign-up")
    end
  end

  describe "POST /newsletter" do
    it "re-renders the page when the email is invalid" do
      post newsletter_path, params: { newsletter_signup: { email: "invalid" } }

      expect(response).to have_http_status(422)
      expect(response.body).to include("must be a valid email address")
    end

    it "redirects with a success message when the signup succeeds" do
      result = instance_double(
        WhatCounts::NewsletterSubscription::Result,
        success?: true,
        message: "Thanks for signing up to the newsletter."
      )

      expect(WhatCounts::NewsletterSubscription).to receive(:new)
        .with(email: "reader@example.com")
        .and_return(instance_double(WhatCounts::NewsletterSubscription, call: result))

      post newsletter_path, params: { newsletter_signup: { email: "reader@example.com" } }

      expect(response).to redirect_to(newsletter_path)
      follow_redirect!
      expect(response.body).to include("Thanks for signing up to the newsletter.")
    end

    it "re-renders the page when the signup fails" do
      result = instance_double(
        WhatCounts::NewsletterSubscription::Result,
        success?: false,
        message: "We could not process your newsletter signup right now. Please try again later."
      )

      expect(WhatCounts::NewsletterSubscription).to receive(:new)
        .with(email: "reader@example.com")
        .and_return(instance_double(WhatCounts::NewsletterSubscription, call: result))

      post newsletter_path, params: { newsletter_signup: { email: "reader@example.com" } }

      expect(response).to have_http_status(502)
      expect(response.body).to include("We could not process your newsletter signup right now. Please try again later.")
    end
  end
end
