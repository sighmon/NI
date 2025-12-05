require 'rails_helper'

describe "categories/index.html.erb", type: :view do
  let(:category) { FactoryBot.create(:category, name: "Environment") }

  before do
    assign(:categories, [category])
    assign(:category, category)

    allow(view).to receive(:app_link).and_return("/app")
    allow(view).to receive(:retina_image_tag).and_return("<img />")
  end

  context "when the user can update" do
    before do
      allow(view).to receive(:can?).with(:update, category).and_return(true)
      render template: "categories/index"
    end

    it "shows the Update colours button" do
      expect(rendered).to include("Update colours")
      expect(rendered).to include("btn btn-xs btn-success")
    end
  end

  context "when the user cannot update" do
    before do
      allow(view).to receive(:can?).with(:update, category).and_return(false)
      render template: "categories/index"
    end

    it "does not show the Update colours button" do
      expect(rendered).not_to include("Update colours")
    end
  end
end
