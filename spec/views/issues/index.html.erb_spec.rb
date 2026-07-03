require 'rails_helper'

describe "issues/index.html.erb", type: :view do
  let(:issue) { FactoryBot.create(:published_issue, title: "June 2026 issue", number: 565) }

  before do
    assign(:issues, [issue])
    assign(:issue, issue)
    assign(:pagy, double("Pagy"))
    assign(:page_description, "An archive of New Internationalist magazines.")

    allow(view).to receive(:retina_image_tag).and_return("<img />")
    allow(view).to receive(:pagy_bootstrap_nav).and_return("PAGY NAV")
    allow(view).to receive(:can?).and_return(false)
    Settings.issue_price = 750
  end

  it "renders issues index structured data into the head slot" do
    render template: "issues/index"

    structured_data = view.content_for(:structured_data)
    expect(structured_data).to include('type="application/ld+json"')
    expect(structured_data).to include('"@type":"CollectionPage"')
    expect(structured_data).to include('"@type":"ItemList"')
    expect(structured_data).to include('"name":"June 2026 issue"')
    expect(structured_data).to include('"offers":{"@type":"Offer"')
    expect(structured_data).to include('"priceCurrency":"AUD"')
    expect(structured_data).to include('"price":"7.50"')
  end
end
