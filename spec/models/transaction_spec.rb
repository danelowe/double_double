module DoubleDouble
  describe Transaction do

    before(:each) do
      @cash = DoubleDouble::Asset.create!(name:'Cash_11', number: 1011)
      @loan = DoubleDouble::Liability.create!(name:'Loan_12', number: 1012)

      # dummy objects to stand-in for a context
      @campaign1 = DoubleDouble::Asset.create!(name:'campaign_test1', number: 9991)
      @campaign2 = DoubleDouble::Asset.create!(name:'campaign_test2', number: 9992)
    end

    it 'should create a transaction using the create! method' do
      -> {
        Transaction.create!(
          description: 'spec transaction 01',
          debits:  [{account: 'Cash_11', amount: 10}],
          credits: [{account: 'Loan_12', amount:  9},
                    {account: 'Loan_12', amount:  1}])

      }.should change(DoubleDouble::Transaction, :count).by(1)
    end

    it 'should not create a transaction using the build method' do
      -> {
        Transaction.build(
          description: 'spec transaction 01',
          debits:  [{account: 'Cash_11', amount: 100_000}],
          credits: [{account: 'Loan_12', amount: 100_000}])
      }.should change(DoubleDouble::Transaction, :count).by(0)
    end

    it 'should not be valid without a credit amount' do
      # No credit_amount element
      t1 = Transaction.build(
        description: 'spec transaction 01',
        debits:  [{account: 'Cash_11', amount: 100_000}])
      t1.should_not be_valid
      t1.errors['base'].should include('Transaction must have at least one credit amount')
      t1.errors['base'].should include('The credit and debit amounts are not equal')
      # An empty credit_amount element
      t2 = Transaction.build(
        description: 'spec transaction 01',
        debits:  [{account: 'Cash_11', amount: 100_000}],
        credits: [])
      t2.should_not be_valid
      t2.errors['base'].should include('Transaction must have at least one credit amount') 
      t2.errors['base'].should include('The credit and debit amounts are not equal')
    end

    it 'should raise a RecordInvalid without a credit amount' do
      -> {
      Transaction.create!(
        description: 'spec transaction 01',
        debits:  [{account: 'Cash_11', amount: 100_000}],
        credits: [])
      }.should raise_error(ActiveRecord::RecordInvalid)
    end

    it 'should not be valid with an invalid credit amount' do
      -> {
        Transaction.create!(
          description: 'spec transaction 01',
          credits: [{account: 'Loan_12', amount: nil}],
          debits:  [{account: 'Cash_11', amount: 100_000}])
      }.should raise_error(ArgumentError)
    end

    it 'should not be valid without a debit amount' do
      # No credit_amount element
      t1 = Transaction.build(
        description: 'spec transaction 01',
        credits:  [{account: 'Loan_12', amount: 100_000}])
      t1.should_not be_valid
      t1.errors['base'].should include('Transaction must have at least one debit amount')
      t1.errors['base'].should include('The credit and debit amounts are not equal')
      # An empty credit_amount element
      t2 = Transaction.build(
        description: 'spec transaction 01',
        credits: [{account: 'Loan_12', amount: 100_000}],
        debits:  [])
      t2.should_not be_valid
      t2.errors['base'].should include('Transaction must have at least one debit amount')
      t2.errors['base'].should include('The credit and debit amounts are not equal')
    end

    it 'should not be valid with an invalid debit amount' do
      -> {
        Transaction.create!(
          description: 'spec transaction 01',
          credits: [{account: 'Cash_11', amount: 100_000}],
          debits:  [{account: 'Loan_12', amount: nil}])
      }.should raise_error(ArgumentError)
    end

    it 'should not be valid without a description' do
      t = Transaction.build(
          description: '',
          debits:  [{account: 'Cash_11', amount: 100_000}],
          credits: [{account: 'Loan_12', amount: 100_000}])
      t.should_not be_valid
      t.errors[:description].should == ["can't be blank"]
    end

    it 'should require the debit and credit amounts to cancel' do
      t = Transaction.build(
        description: 'spec transaction 01',
        credits: [{account: 'Cash_11', amount: 100_000}],
        debits:  [{account: 'Loan_12', amount:  99_999}])
      t.should_not be_valid
      t.errors['base'].should == ['The credit and debit amounts are not equal']
    end

    describe 'context references' do
      it 'should allow a transaction to be built describing the context in the hash' do
        Transaction.create!(
          description: 'Sold some widgets',
          debits:  [{account: 'Cash_11', amount: 60, context: @campaign1},
                    {account: 'Cash_11', amount: 40, context: @campaign2}], 
          credits: [{account: 'Loan_12', amount: 45},
                    {account: 'Loan_12', amount:  5},
                    {account: 'Loan_12', amount: 50, context: @campaign1}])
        Amount.by_context(@campaign1).count.should eq(2)
        Amount.by_context(@campaign2).count.should eq(1)
        @cash.debits_balance(context: @campaign1).should eq(60)
        @cash.debits_balance(context: @campaign2).should eq(40)
      end  
    end

    describe 'readme scenarios' do
      it 'should perform BASIC SCENARIO A correctly' do
        DoubleDouble::Asset.create! name:'Cash', number: 11
        DoubleDouble::Liability.create! name:'Grandpa Loan', number: 12

        # Grandpa was kind enough to loan us $800 USD in cash for college textbooks.  To enter this we will require a transaction which will affect both 'Cash' and 'Grandpa Loan'

        DoubleDouble::Transaction.create!(
          description: 
            'We received a loan from Grandpa',
          debits:[
            {account: 'Cash', amount: '$800'}],
          credits:[
            {account: 'Grandpa Loan', amount: '$800'}])

        # But say that we wanted to return $320 because we were able to purchase a few used books.
        
        DoubleDouble::Transaction.create!(
          description: 
            'Payed back $320 to Grandpa',
          debits:[
            {account: 'Grandpa Loan', amount: '$320'}],
          credits:[
            {account: 'Cash', amount: '$320'}])

        # If we wanted to know how much we still owed Grandpa, we could look at the balance of the account.

        DoubleDouble::Account.find_by_name('Grandpa Loan').balance.to_s.should eq("480.00")
      end
    end
  end
end
