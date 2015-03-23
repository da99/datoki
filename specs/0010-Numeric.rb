
describe Numeric do

  it "fails if number is outside the range" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:age) { smallint 1, 150 }
      }.create :age=>0
    }.message.should.match /age must be between 1 and 150/i
  end

  it "raises an exception if value is a non-numeric varchar." do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:age) { smallint 1, 150 }
      }.create :age=>'twenty-two'
    }.message.should.match /age must be numeric/i
  end

  it "allows nil" do
    Class.new {
      include Datoki
      field(:age) { smallint nil, 1, 99 }
    }.create(:age=>nil).
    clean_data[:age].should == nil
  end

  it "allows nil in an array" do
    Class.new {
      include Datoki
      field(:age) { smallint [nil, 1,2,3,4] }
    }.create(:age=>nil).
    clean_data[:age].should == nil
  end

  it "allows to specify an Array of possible values" do
    Class.new {
      include Datoki
      field(:age) { smallint [1,2,3,4] }
    }.create(:age=>2).
    clean_data[:age].should == 2
  end

  it "fails if value is not in Array of possible values" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:num) { smallint [1,2,3,4] }
      }.create :num=>0
    }.message.should.match /Num can only be: 1, 2, 3, 4/
  end

end # === describe Numeric
