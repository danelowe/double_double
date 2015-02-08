module DoubleDouble
  class ChartOfAccounts < ActiveRecord::Base
    self.table_name = 'double_double_charts_of_accounts'
    has_many :entries
    has_many :accounts
    has_many :assets
    has_many :liabilities
    has_many :equities
    has_many :revenues
    has_many :expenses

    def trial_balance
      assets.balance - (liabilities.balance + equities.balance + revenues.balance - expenses.balance)
    end

    def currency
      code = read_attribute(:currency)
      @currency ||= (code.present? && (code != '')) ? Money::Currency.new(code) : Money.default_currency
    end

    def currency=(value)
      code = value.respond_to?(:iso_code) ? value.iso_code : value
      write_attribute :currency, code
    end

  end
end