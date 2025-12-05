require 'rails_helper'

describe SubscriptionsHelper, type: :helper do
  describe '#subscription_price_table' do
    it 'renders a subscription price table with the correct rows and price calls' do
      # Stub cents_to_dollars so we don't rely on its implementation here
      allow(helper).to receive(:cents_to_dollars) { |_cents| '10.00' }

      # Generic stub so any un-asserted combination still returns a value
      allow(Subscription).to receive(:calculate_subscription_price).and_return(1000)

      # Make sure all the distinct option combinations are used at least once
      expect(Subscription).to receive(:calculate_subscription_price)
        .with(3, autodebit: true).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(6, autodebit: false).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(3, { autodebit: true, paper: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(3, { autodebit: false, paper: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(3, { autodebit: false, paper: true, paper_only: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(12, { autodebit: false, paper: true, paper_only: true, institution: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(12, { autodebit: true, institution: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(12, { autodebit: true, paper: true, institution: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(12, { autodebit: false, institution: true }).at_least(:once).and_return(1000)

      expect(Subscription).to receive(:calculate_subscription_price)
        .with(12, { autodebit: false, paper: true, institution: true }).at_least(:once).and_return(1000)

      html = helper.subscription_price_table

      # Basic structure
      expect(html).to include('<table')
      expect(html).to include('class="table table-striped subscription-price-table"')
      expect(html).to include('<thead')
      expect(html).to include('<tbody')

      # Header row
      expect(html).to include('Subscription options')
      expect(html).to include('3 months')
      expect(html).to include('6 months')
      expect(html).to include('12 months')

      # Row labels (copy-pasted from helper to avoid typos)
      expect(html).to include('Ongoing Automatic debit digital subscription')
      expect(html).to include('Once-off digital subscription')
      expect(html).to include('Ongoing Automatic debit subscription, Digital + Paper')
      expect(html).to include('Once-off subscription, Digital + Paper')
      expect(html).to include('Paper only subscription')
      expect(html).to include('Institution subscription payment, Paper only')
      expect(html).to include('Institution automatic debit subscription payment, Digital only')
      expect(html).to include('Institution automatic debit subscription payment, Digital + Paper')
      expect(html).to include('Institution once-off subscription payment, Digital only')
      expect(html).to include('Institution once-off subscription payment, Digital + Paper')

      # At least one price cell rendered
      expect(html).to include('$10.00')
    end
  end
end
