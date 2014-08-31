
describe 'No type' do

  it "fails when String is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { min 3 }
      }.create :title => '1'
    }.message.should.match /Title must have a length of at least 3/i
  end

  it "fails when Array is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:names) { min 4 }
      }.create :names => %w{ 1 2 }
    }.message.should.match /Names must have at least 4/
  end

  it "does not allow nil by default" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:body) { }
      }.create :body => nil
    }.message.should.match /Body is required/i
  end

  it "requires field by default" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { }
      }.create
    }.message.should.match /Title is required/i
  end

  it "allows nil if specified" do
    Class.new {
      include Datoki
      field(:title) { min 2 }
      field(:body) { allow :nil }
    }.
    create(:title => 'title', :body => nil).
    clean_data[:body].should == nil
  end

end # === describe 'No type' ========================================

describe String do # ================================================

  it "fails when string is shorter than required length: string x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:name) { string 3 }
      }.create :name=>'1234'
    }.message.should.match /needs to be 3 in length/
  end

  it "fails when string is shorter than min: min x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { string; min 4 }
      }.create :title => '123'
    }.message.should.match /must be at least 4/
  end

  it "fails when string is longer than max: max x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { string; max 5 }
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
        allow :nil
      }
    }.create()
    r.clean_data[:title].should == nil
  end

  it "sets field to return value of :set_to" do
    Class.new {
      includ Datoki
      field(:title) {
        string
        set_to :custom_error
        def custom_error
          'Custom title'
        end
      }
    }.
    create(:title => 'My Title').
    clean_data[:title].should.match /Custom title/
  end

  it "can prevent string from being stripped" do
    Class.new {
      include Datoki
      field(:title) {
        string
        disable :strip
      }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == ' my title '
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


describe "on :create" do

  it "after all fields have been cleaned" do
    Class.new {

      include Datoki

      on :create, def collect_values
        clean_data[:values] = clean_data.values.join ', '
      end

      field(:title) { default 'default title' }

      field(:body) { default 'default body' }

    }.
    create.
    clean_data[:values].should == 'default title, default body'
  end

  it "runs after validation for a field" do
    Class.new {
      include Datoki
      field(:body) {
        on :create, def add_stuff
          clean_data[:body] << ' with new stuff'
        end

        default 'default body'
      }
    }.
    create.
    clean_data[:body].should == 'default body with new stuff'
  end

end # === describe on :create


