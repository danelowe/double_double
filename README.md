# double_double
[![Build Status](https://travis-ci.org/crftr/double_double.png)](https://travis-ci.org/crftr/double_double)
[![Dependency Status](https://gemnasium.com/crftr/double_double.png)](https://gemnasium.com/crftr/double_double)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/crftr/double_double)

A double-entry accrual accounting system for your application. Currency-agnostic but uses the Money gem. Account holder support and contexts are built-in.

## Installation

### Gem

Add this line to your application's Gemfile:

    gem 'double_double'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install double_double

### Database structure

Create the expected database structure.  If using Rails, generate a migration:

    $ rails generate migration CreateDoubleDouble

Edit the migration to match:

```ruby
class CreateDoubleDouble < ActiveRecord::Migration
  def change
    create_table :double_double_accounts do |t|
      t.string  :name,          null: false
      t.integer :number,        null: false
      t.string  :type,          null: false
      t.boolean :contra,        default: false
    end
    add_index :double_double_accounts, [:name, :type]

    create_table :double_double_transactions do |t|
      t.string :description
      t.references :transaction_type
      t.timestamps
    end
    add_index :double_double_transactions, :transaction_type_id

    create_table :double_double_transaction_types do |t|
      t.integer :number,        null: false
      t.string :description,    null: false
    end
    add_index :double_double_transaction_types, :number

    create_table :double_double_amounts do |t|
      t.string :type
      t.references :account
      t.references :transaction
      t.references :accountee,  polymorphic: true
      t.references :context,    polymorphic: true
      t.references :initiator,  polymorphic: true
      t.integer :amount_cents, limit: 8, default: 0, null: false
      t.string  :currency
    end
    add_index :double_double_amounts, :context_id
    add_index :double_double_amounts, :context_type
    add_index :double_double_amounts, :initiator_id
    add_index :double_double_amounts, :initiator_type
    add_index :double_double_amounts, :accountee_id
    add_index :double_double_amounts, :accountee_type
    add_index :double_double_amounts, :type
    add_index :double_double_amounts, [:account_id, :transaction_id]
    add_index :double_double_amounts, [:transaction_id, :account_id]
  end
end
```

Rake the new migration

    $ rake db:migrate

## Overview

[Double-entry accounting][1] practices have been [traced back to the 13th century][2].  double_double strives to make accepted practices accessible and relatively easy to implement within other applications.

[1]: http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system
[2]: http://en.wikipedia.org/wiki/Double-entry_bookkeeping_system#History

As with many off-the-shelf accounting systems, this project supports:
* **Accountee**: an account holder.
* **Context**: to track activity on invoices, purchase orders, jobs, campaigns, etc.
* **Initiator**: *who* authorized or performed the action.

### Accounts

All accounts created in a double-entry system make up the [chart of accounts][3].  This collection of accounts will determine how money is tracked as it moves through the system.  It is important to design and create the chart of accounts prior to creating transactions.  *If we want people to hold "an individual account" in this system, we will configure them as an accountee, not with an new account.  *See the section on accountees* *

[3]: http://en.wikipedia.org/wiki/Chart_of_accounts

In double_double, all accounts created are considered to be the chart of accounts.  All accounts are "on the books."

**Account Class**         | **Normal Balance** | **Description**                                    | **Example Uses**
------------------------- | ------------------ | -------------------------------------------------- | -------------------------------------------
`DoubleDouble::Asset`     | Debit              | Resources owned or controlled                      | Cash, Office Computers, Grandma's Jewelry
`DoubleDouble::Liability` | Credit             | Obligations                                        | Accounts Payable, Bank Loan
`DoubleDouble::Equity`    | Credit             | The claim to assets after all liabilities are paid | Paid-In Capital, Dividends, Retained Earnings
`DoubleDouble::Revenue`   | Credit             | Income                                             | Sales, Interest Earned
`DoubleDouble::Expense`   | Debit              | Expenditures                                       | Utilities, Salaries, Rent, Taco Tuesday

Accounts have the following attributes:

1. name
2. number, for reporting purposes
3. contra flag, optional `default: false`

An example 'Cash' asset account as account number `20`

```ruby
DoubleDouble::Asset.create! name: 'Cash', number: 20
```

An example 'Sales' revenue account and a 'Discounts' contra revenue account.

```ruby
DoubleDouble::Revenue.create! name: 'Sales',     number: 40
DoubleDouble::Revenue.create! name: 'Discounts', number: 50, contra: true
```

Contra accounts are used to offset a related account of the same class.  *The example above is a common method to track sales.  The full **sales value** of the sale would be attributed to 'Sales' while any discounts given would be added to 'Discounts.'*


### Amounts & Transactions

TODO: Transaction basics
TODO: Amount basics
TODO: Accountees
TODO: Contexts
TODO: Initiated_by

## Example Scenarios

TODO: Write a basic, realistic, and complex scenario.

## Tests

All code is backed by Rspec tests.  Clone this repository and either `rspec spec` or `rake spec` if Rake is installed.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes & tests (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Notes

double_double was influenced by mbulat's plutus project and regularly working with quickbooks.

