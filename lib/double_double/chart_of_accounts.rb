module DoubleDouble
  class ChartOfAccounts < ActiveRecord::Base
    self.table_name = 'double_double_charts_of_accounts'

    def currency
      @currency ||= Money::Currency.new(read_attribute(:currency))
    end

    def currency=(value)
      code = value.respond_to?(:iso_code) ? value.iso_code : value
      write_attribute :currency, code
    end

  end
end