
describe 'record_errors' do

  it "prevents failing with an exception" do
    r = Class.new {
      include Datoki
      record_errors
      field(:title) { string }
    }.create

    r.errors.should == {:title=>{:msg=>'Title is required.', :value=>nil}}
  end

end # === describe record_errors ====================================

describe 'No type' do

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
      field(:title) { string 2, 255 }
      field(:body) { string nil }
    }.create(:title => 'title', :body => nil).
    clean_data[:body].should == nil
  end

end # === describe 'No type' ========================================

describe String do # ================================================

  it "fails when String is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { string 3, 255 }
      }.create :title => '1'
    }.message.should.match /Title must be at least 3/i
  end

  it "fails when string is shorter than required length: string x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:name) { string 3, 255 }
      }.create :name=>'1234'
    }.message.should.match /needs to be 3 in length/
  end

  it "fails when string is shorter than min" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { string 4, 200 }
      }.create :title => '123'
    }.message.should.match /must be at least 4/
  end

  it "fails when string is longer than max" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { string 0, 5 }
      }.create :title => '123456'
    }.message.should.match /Title has a maximum length of 5/
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
        string nil
      }
    }.create()
    r.clean_data[:title].should == nil
  end

  it "sets field to return value of :set_to" do
    Class.new {
      include Datoki
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

  it "strips strings by default" do
    Class.new {
      include Datoki
      field(:title) { string }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == 'my title'
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

  it "sets to nil if String is .strip.empty?" do
    r = Class.new {
      include Datoki
      record_errors
      field(:title) { string nil }
    }.create :title => '  '

    r.clean_data[:title].should == nil
  end

end # === describe Datoki ===


describe Array do

  it "fails when Array is less than min:" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:names) { array 4, 10 }
      }.create :names => %w{ 1 2 }
    }.message.should.match /Names must have at least 4/
  end

  it "fails if Array is not the right size: max x" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:nicknames) { array; max 6 }
      }.create :nicknames=>%w{ a b c d e f g h }
    }.message.should.match /Nicknames has a maximum of 6/
  end

end # === describe Array

describe Integer do

  it "fails if Integer is outside the range" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:age) { integer 1, 150 }
      }.create :age=>0
    }.message.should.match /age must be between 1 and 150/i
  end

  it "raises an exception if value is a non-numeric String." do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:age) { integer 1, 150 }
      }.create :age=>'twenty-two'
    }.message.should.match /age must be numeric/i
  end

end # === describe Integer

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

describe "on :update" do

  it "does not override old, unset fields with default values" do
    r = Class.new {
      include Datoki
      field(:title) { default 'my title' }
      field(:body) { default 'my body' }
    }.new(:title=>'old title')
    r.update :body=>'new body'
    r.clean_data.should == {:body=>'new body'}
  end

end # === describe on :update

describe "Datoki.db" do

  before {
    @klass = Class.new {
      include Datoki
      table "datoki_test"
    }
  }

  it "imports field names into class" do
    @klass.fields.keys.should == [:id, :parent_id, :title, :body]
  end

  it "imports field types into class" do
    @klass.fields.values.map { |meta| meta[:type] }.should == [:integer, :integer, :string, :string]
  end

end # === describe Datoki.db

describe "Datoki.db" do

  it "raises Schema_Conflict when their is a :allow_null conflict"
  it "raises Schema_Conflict when their is a :max_length conflict"
  it "raises Schema_Conflict when default value != null and :allow_null = true"
  it "raises Schema_Conflict if :allow_null = true, and allow(:nil) is not used for confirmation"

end # === describe Datoki.db

describe "Datoki.db :string" do

  before {
    @klass = Class.new {
      include Datoki
      table "datoki_test"
    }
  }

  it "imports max length" do
    @klass.fields[:title][:max].should == 123
  end

  it "sets :min to 1" do
    @klass.fields[:title][:min].should == 1
  end

end # === describe Datoki.db :string

describe 'Datoki.db :integer' do

  before {
    reset_db

    @klass = Class.new {
      include Datoki
      table "datoki_test"
    }
  }

  it "sets :min to 1" do
    @klass.fields[:parent_id][:min].should == 1
  end

end # === Datoki.db :integer




