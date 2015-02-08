module DoubleDouble
  describe ChartOfAccounts do
    it "Ensures correct currency is used for account balances" do
      ChartOfAccounts.new(currency: 'NZD').assets.balance.currency.should eq Money::Currency.new('NZD')
    end
  end
end

