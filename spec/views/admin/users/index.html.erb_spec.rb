require 'rails_helper'

describe "admin/users/index.html.erb", type: :view do
  let(:user) { FactoryBot.create(:user) }

  before do
    # Core data shown in summary section
    assign(:user, user)
    assign(:total_users, 10)
    assign(:subscribers, [double("sub1"), double("sub2")])
    assign(:institutions, [double("inst1")])
    assign(:students, [])
    assign(:uk_users, [double("uk1"), double("uk2"), double("uk3")])
    assign(:guest_passes, [double("gp1")])

    assign(:pagy, double("Pagy"))
    assign(:users, [user])

    # Helpers we don't want to exercise here
    allow(view).to receive(:pagy_bootstrap_nav).and_return("PAGY NAV")

    # Sorting helpers used by ApplicationHelper#sortable in _users_table
    allow(view).to receive(:sort_column).and_return("created_at")
    allow(view).to receive(:sort_direction).and_return("asc")

    # Default permission behaviour — override in specific contexts
    allow(view).to receive(:can?).and_return(false)
  end

  context "when the user cannot update users" do
    before do
      render template: "admin/users/index"
    end

    it "renders the page title" do
      expect(rendered).to include("All users")
    end

    it "does not show admin action buttons" do
      expect(rendered).not_to include("Download a CSV file")
      expect(rendered).not_to include("Try the new way")
      expect(rendered).not_to include("List all users on this page")
    end

    it "renders summary statistics" do
      expect(rendered).to include("10 users")
      expect(rendered).to include("2 subscribers")
      expect(rendered).to include("1 institution")
      expect(rendered).to include("0 students")
      expect(rendered).to include("3 users")      # UK users
      expect(rendered).to include("1 guest pass")
    end

    it "renders pagy pagination twice" do
      expect(rendered.scan("PAGY NAV").size).to eq(2)
    end

    it "renders the users table partial" do
      expect(view).to have_rendered(partial: "_users_table")
      # if your partial path is namespaced, you can use:
      # expect(view).to have_rendered(partial: "admin/users/_users_table")
    end

    it "renders back and new buttons" do
      expect(rendered).to include("New User")
      expect(rendered).to include("Back")
    end
  end

  context "when the user can update users" do
    before do
      allow(view).to receive(:can?).with(:update, user).and_return(true)
      render template: "admin/users/index"
    end

    it "shows CSV download button" do
      expect(rendered).to include("Download a CSV file")
    end

    it "shows Try the new way button" do
      expect(rendered).to include("Try the new way")
    end

    it "shows List all users button" do
      expect(rendered).to include("List all users on this page")
    end
  end
end
