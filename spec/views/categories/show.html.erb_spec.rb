require 'rails_helper'

describe "categories/show.html.erb", type: :view do
  let(:category) do
    FactoryBot.create(:category, display_name: "World>Politics").tap do |c|
      # ensure this returns something nice for the header/subheading
      allow(c).to receive(:short_display_name).and_return("World / Politics")
    end
  end

  let(:issue) do
    FactoryBot.create(:issue, title: "July 2020 issue")
  end

  let(:article) do
    FactoryBot.create(:article, issue: issue, title: "Democracy in crisis")
  end

  before do
    assign(:category, category)
    assign(:articles, [article])
    assign(:pagy, double("Pagy"))

    # Helpers we don't want to exercise
    allow(view).to receive(:retina_image_tag).and_return("<img />")
    allow(view).to receive(:app_link).and_return("/app")
    allow(view).to receive(:pagy_bootstrap_nav).and_return("PAGY NAV")

    # IMPORTANT: default can? stub for ANY arguments
    allow(view).to receive(:can?).and_return(false)
  end

  context "when the user can update and destroy the category" do
    before do
      allow(view).to receive(:can?).with(:update, category).and_return(true)
      allow(view).to receive(:can?).with(:destroy, category).and_return(true)

      render template: "categories/show"
    end

    it "shows the edit and destroy buttons" do
      expect(rendered).to include("Edit")
      expect(rendered).to include("btn btn-primary btn-xs")

      # This is what is actually rendered:
      expect(rendered).to include("Delete")
      expect(rendered).to include("btn btn-xs btn-danger")
    end
  end

  context "when the user cannot update the category" do
    before do
      # We already have can? defaulting to false for all args,
      # so nothing else needed here.
      render template: "categories/show"
    end

    it "does not show edit or destroy buttons" do
      expect(rendered).not_to include("Edit")
      expect(rendered).not_to include("Destroy")
    end

    it "renders the page header with display_name gsub'd" do
      # display_name "World>Politics" becomes "World/Politics"
      expect(rendered).to include("<h1>World/Politics</h1>")
    end

    it "renders the subheading with short_display_name" do
      expect(rendered).to include("Articles about World / Politics, ordered by date.")
    end

    it "renders article cards via the category_article partial" do
      expect(view).to have_rendered(partial: "_category_article")
    end

    it "renders the article table with title, issue and publication date" do
      expect(rendered).to include("Article title")
      expect(rendered).to include("From magazine")
      expect(rendered).to include("Publication date")

      expect(rendered).to include("Democracy in crisis")
      expect(rendered).to include("July 2020 issue")
      # publication formatting: "%B, %Y"
      expect(rendered).to match(/\w+,\s+\d{4}/)
    end

    it "renders pagination (Pagy) above and below the table" do
      expect(rendered.scan("PAGY NAV").size).to eq(2)
    end

    it "renders the breadcrumb trail" do
      expect(rendered).to include("Home")
      expect(rendered).to include("Categories")
      expect(rendered).to include("World / Politics")
    end

    it "renders a Back button linking to categories" do
      expect(rendered).to include("Back")
      expect(rendered).to include(categories_path)
    end
  end
end
