FactoryGirl.define do
  factory :chart_of_accounts, class: DoubleDouble::ChartOfAccounts do |chart_of_accounts|
    chart_of_accounts.name   { FactoryGirl.generate(:chart_of_accounts_name)  }
    chart_of_accounts.code   { FactoryGirl.generate(:chart_of_accounts_code)}
    chart_of_accounts.currency 'NZD'
  end
  
  sequence :chart_of_accounts_name do |n|
    "Chart of Accounts #{n}"
  end

  sequence :chart_of_accounts_code do |n|
    "chart_of_accounts#{n}"
  end
end
