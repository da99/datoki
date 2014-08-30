
describe String do

  it "fails when string is shorter than required length: string x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :name do
          string 3
        end
      }.create :name=>'1234'
    }.message.should.match /must be 3 characters long/
  end

  it "fails when string is shorter than min: min x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { min 4 }
      }.create :title => '123'
    }.message.should.match /must be at least 4/
  end

  it "fails when string is longer than max: max x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { max 5 }
      }.create :title => '123456'
    }.message.should.match /must be less than 5/
  end

  it "fails when string does not match pattern: match /../" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title do
          on :create do
            match /^[a-zA-Z0-9]+$/i, "Title must be only: alphanumeric"
          end
        end
      }.create :title => '$! title'
    }.message.should.match /Title must be only: alphanumeric/
  end

  it "requires a String even if not set: required " do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { on(:create) { required } }
      }.create()
    }.message.should.match /Title is required/
  end

  it "fails if :be lambda returns a string instead of true" do
    should.raise(Datoki::Invalid) {
      Class.new {
        includ Datoki
        field(:title) {
          on(:create) {
            be lambda { 'Custom error message' }
          }
        }
      }.create :title => 'My Title'
    }.message.should.match /Custom error message/
  end

  it "strips string" do
    r = Class.new {
      inclide Datoki
      field(:title) { on(:create) { strip } }
    }.create :title => ' my title '
    r.clean_data[:title].should == 'my title'
  end

end # === describe Datoki ===
