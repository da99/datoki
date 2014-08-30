
describe 'No type' do

  it "fails when String is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title { min 3 }
      }.create :title => '1'
    }.message.should.match /must be at least 3/
  end

  it "fails when Array is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title { min 3 }
      }.create :title => %w{ 1 2 }
    }.message.should.match /must has at least 3/
  end

end # === describe 'No type'

describe String do

  it "fails when string is shorter than required length: string x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :name { string 3 }
      }.create :name=>'1234'
    }.message.should.match /must be 3 characters long/
  end

  it "fails when string is shorter than min: min x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) {
          string
          min 4
        }
      }.create :title => '123'
    }.message.should.match /must be at least 4/
  end

  it "fails when string is longer than max: max x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) {
          string
          max 5
        }
      }.create :title => '123456'
    }.message.should.match /must be less than 5/
  end

  it "fails when string does not match pattern: match /../" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title do
          string
          match /^[a-zA-Z0-9]+$/i, "Title must be only: alphanumeric"
        end
      }.create :title => '$! title'
    }.message.should.match /Title must be only: alphanumeric/
  end

  it "allows String to be nil" do
    r = Class.new {
      include Datoki
      field(:title) {
        string
        enable :nil
      }
    }.create()
    r.clean_data[:title].should == nil
  end

  it "fails if :be lambda returns a string instead of true" do
    should.raise(Datoki::Invalid) {
      Class.new {
        includ Datoki
        field(:title) {
          string
          be lambda { 'Custom error message' }
        }
      }.create :title => 'My Title'
    }.message.should.match /Custom error message/
  end

  it "can prevent string from being stripped" do
    r = Class.new {
      include Datoki
      field(:title) {
        string
        disable :strip
      }
    }.create :title => ' my title '
    r.clean_data[:title].should == ' my title '
  end

end # === describe Datoki ===


describe Array do

  it "fails if Array is not the right size: array x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { array 6 }
      }.create :keys=>[1,2,3,4]
    }.message.should.match /must be 6/
  end

end # === describe Array




