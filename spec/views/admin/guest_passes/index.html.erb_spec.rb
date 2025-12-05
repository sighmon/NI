require 'rails_helper'

RSpec.describe "admin/guest_passes/index.html.erb", type: :view do
  it "renders a list of guest passes with pagination" do
    user    = FactoryBot.create(:user)
    issue   = FactoryBot.create(:issue)
    article = FactoryBot.create(:article, issue: issue, title: "Amazing Article")

    guest_pass = FactoryBot.create(
      :guest_pass,
      user: user,
      article: article,
      key: "ABC123",
      use_count: 5
    )

    assign(:pagy, double("Pagy"))
    assign(:guest_passes, [guest_pass])

    # Don’t depend on Pagy internals in this spec
    allow(view).to receive(:pagy_bootstrap_nav).and_return("PAGY NAV")

    # Stub the helper that builds the guest pass URL
    allow(view).to receive(:generate_guest_pass_link_string)
      .with(guest_pass)
      .and_return("http://example.com/guest_passes/ABC123")

    # Make sure score has a value for number_with_precision
    allow(article).to receive(:score).and_return(1.234)

    # This will now look for app/views/admin/guest_passes/index.html.erb
    render template: "admin/guest_passes/index"

    # Header & headings
    expect(rendered).to include("Guest Passes")
    expect(rendered).to include("User")
    expect(rendered).to include("Article")
    expect(rendered).to include("Key")
    expect(rendered).to include("Views")
    expect(rendered).to include("Score")
    expect(rendered).to include("Action")

    # Row content
    expect(rendered).to include(user.to_s)
    expect(rendered).to include("Amazing Article")
    expect(rendered).to include("ABC123")
    expect(rendered).to include("5")
    expect(rendered).to include("1.234")

    # Pagination appears twice (top & bottom)
    expect(rendered.scan("PAGY NAV").size).to eq(2)

    # Back button
    expect(rendered).to include("Back")
  end
end
