module DoubleDouble
  module AccountCollectionExtension
    def balance
      inject(Money.new(0, currency)) {|sum, acct| acct.contra ? (sum - acct.balance) : (sum + acct.balance)}
    end

    def currency
      @association ? @association.owner.currency : Money.default_currency
    end
  end
  # The Account class represents accounts in the system. Each account must be subclassed as one of the following types:
  #
  #   TYPE        | NORMAL BALANCE    | DESCRIPTION
  #   --------------------------------------------------------------------------
  #   Asset       | Debit             | Resources owned by the Business Entity
  #   Liability   | Credit            | Debts owed to outsiders
  #   Equity      | Credit            | Owners rights to the Assets
  #   Revenue     | Credit            | Increases in owners equity
  #   Expense     | Debit             | Assets or services consumed in the generation of revenue
  #
  # Each account can also be marked as a "Contra Account". A contra account will have it's
  # normal balance swapped. For example, to remove equity, a "Drawing" account may be created
  # as a contra equity account as follows:
  #
  #   DoubleDouble::Equity.create(name: "Drawing", number: 2002, contra: true)
  #
  # At all times the balance of all accounts should conform to the "accounting equation"
  #   DoubleDouble::Assets = Liabilties + Owner's Equity
  #
  # Each sublclass account acts as it's own ledger. See the individual subclasses for a
  # description.
  #
  # @abstract
  #   An account must be a subclass to be saved to the database. The Account class
  #   has a singleton method {trial_balance} to calculate the balance on all Accounts.
  #
  # @see http://en.wikipedia.org/wiki/Accounting_equation Accounting Equation
  # @see http://en.wikipedia.org/wiki/Debits_and_credits Debits, Credits, and Contra Accounts
  #
  class Account < ActiveRecord::Base
    self.table_name = 'double_double_accounts'

    has_many :credit_amounts
    has_many :debit_amounts
    has_many :credit_entries, through: :credit_amounts, source: :entry
    has_many :debit_entries,  through: :debit_amounts,  source: :entry
    belongs_to :chart_of_accounts

    validates_presence_of :type, :name, :number
    validates_uniqueness_of :name, :number, scope: :chart_of_accounts_id
    validates_length_of :name, :minimum => 1

    class << self

      def all
        super.extending AccountCollectionExtension
      end

      # The trial balance of all accounts in the system. This should always equal zero,
      # otherwise there is an error in the system.
      #
      # @return [Money] The value balance of all accounts
      def trial_balance
        raise(NoMethodError, "undefined method 'trial_balance'") unless self == DoubleDouble::Account
        ChartOfAccounts.new.trial_balance
      end

      def balance
        raise(NoMethodError, "undefined method 'balance'") if self == DoubleDouble::Account
        where(chart_of_accounts_id: nil).balance
      end

      def named account_name
        find_by(name: account_name.to_s)
      end

      def numbered account_number
        find_by(number: account_number.to_i)
      end
    end

    def credits_balance(hash = {})
      side_balance(false, hash)
    end

    def debits_balance(hash = {})
      side_balance(true, hash)
    end

    def currency
      chart_of_accounts.present? ? chart_of_accounts.currency : Money.default_currency
    end

    protected

      def side_balance(is_debit, hash)
        a = is_debit ? debit_amounts : credit_amounts
        a = a.by_context(hash[:context])                   if hash.has_key? :context
        a = a.by_subcontext(hash[:subcontext])             if hash.has_key? :subcontext
        a = a.by_accountee(hash[:accountee])               if hash.has_key? :accountee
        a = a.by_entry_type(hash[:entry_type]) if hash.has_key? :entry_type
        a.balance
      end

      # The balance method that derived Accounts utilize.
      #
      # Normal Debit Accounts:
      # if contra { credits_balance(hash) - debits_balance(hash)  }
      # else      { debits_balance(hash)  - credits_balance(hash) }
      #
      # Normal Credit Accounts:
      # if contra { debits_balance(hash)  - credits_balance(hash) }
      # else      { credits_balance(hash) - debits_balance(hash)  }
      #
      # @return [Money] The balance of the account instance
      def child_account_balance(is_normal_debit_account, hash = {})
        raise(NoMethodError, "undefined method 'balance'") if self == DoubleDouble::Account
        if (is_normal_debit_account && contra) || !(is_normal_debit_account || contra)
          credits_balance(hash) - debits_balance(hash)
        else
          debits_balance(hash) - credits_balance(hash)
        end
      end
  end
end







