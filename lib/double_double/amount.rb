module DoubleDouble
  module AmountCollectionExtension
    def balance
      loaded? ? inject(Money.new(0, currency)){|sum, amt| sum + amt.amount} : Money.new(sum(:amount_cents), currency)
    end

    def currency
      @association ? @association.owner.currency : Money.default_currency
    end
  end
  # The Amount class represents debit and credit amounts in the system.
  #
  # @abstract
  #   An amount must be a subclass as either a debit or a credit to be saved to the database. 
  #
  class Amount < ActiveRecord::Base
    self.table_name = 'double_double_amounts'

    belongs_to :entry
    belongs_to :account
    belongs_to :accountee,  polymorphic: true
    belongs_to :context,    polymorphic: true
    belongs_to :subcontext, polymorphic: true
    
    scope :by_accountee,        ->(a) { where(accountee_id:  a.id, accountee_type:  a.class.base_class) }
    scope :by_context,          ->(c) { where(context_id:    c.id, context_type:    c.class.base_class) }
    scope :by_subcontext,       ->(s) { where(subcontext_id: s.id, subcontext_type: s.class.base_class) }
    scope :by_entry_type,       ->(t) { joins(:entry).where(double_double_entries: {entry_type_id: t}) }

    validates_presence_of :type, :entry, :account
    validates :amount_cents, numericality: {greater_than: 0}

    # [dane] Workaround to deal with the fact that composed of will never use the converter for a nil value. Otherwise,
    # we could have simply passed a converter to composed_of. See ActiveRecord::Aggregations#writer_method
    #
    def amount=(part)
      unless part.is_a?(Money)
        part = Monetize.parse(part, currency)
        raise(ArgumentError, "Can't convert #{value.class} to Money") unless part
      end
      raise "Currency #{part.currency_as_string} should be #{currency.iso_code}" unless part.currency == currency
      self.amount_cents = part.cents
      @aggregation_cache[:amount] = part.freeze
    end

    def amount
      @aggregation_cache[:amount] ||= Money.new(amount_cents, currency)
    end

    def self.all
      super.extending AmountCollectionExtension
    end

    def currency
      account.present? ? account.currency : Money.default_currency
    end
  end
end