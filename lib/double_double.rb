require 'active_record'
require 'money'
require 'monetize'

require 'double_double/version'

# Accounts
require 'double_double/account'
require 'double_double/normal_credit_account'
require 'double_double/normal_debit_account'
require 'double_double/asset'
require 'double_double/equity'
require 'double_double/expense'
require 'double_double/liability'
require 'double_double/revenue'

# Amounts
require 'double_double/amount'
require 'double_double/credit_amount'
require 'double_double/debit_amount'

# entries
require 'double_double/entry'
require 'double_double/entry_type'

module DoubleDouble
  class Configuration
    attr_accessor :allow_currency_conversion

    def initialize
      self.allow_currency_conversion = false
    end
  end

  def self.configuration
    @configuration ||=  Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end
end