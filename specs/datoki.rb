
describe 'record_errors' do

  it "prevents failing with an exception" do
    r = Class.new {
      include Datoki
      record_errors
      field(:title) { varchar }
    }.create

    r.errors.should == {:title=>{:msg=>'Title is required.', :value=>nil}}
  end

end # === describe record_errors ====================================

describe 'No type' do

  it "requires type to be specified" do
    should.raise(RuntimeError) {
      Class.new {
        include Datoki
        field(:title) {  }
      }
    }.message.should.match /Type not specified/
  end

end # === describe 'No type' ========================================

describe :varchar do # ================================================

  it "requires field by default" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar }
      }.create
    }.message.should.match /Title is required/i
  end

  it "raises RuntimeError if allow :null and :min = 0" do
    should.raise(RuntimeError) {
      Class.new {
        include Datoki
        field(:name) { varchar nil, 0, 50 }
      }
    }.message.should.match /varchar can't be both: allow :null && :min = 0/
  end

  it "fails when varchar is less than min: varchar x, y" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 3, 255 }
      }.create :title => '1'
    }.message.should.match /Title must be between 3 and 255 characters/i
  end

  it "fails when varchar is longer than max" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field(:title) { varchar 0, 5 }
      }.create :title => '123456'
    }.message.should.match /Title must be between 0 and 5 characters/
  end

  it "fails when varchar does not match pattern: match /../" do
    should.raise(Datoki::Invalid) {
      Class.new {
        include Datoki
        field :title do
          varchar
          match /^[a-zA-Z0-9]+$/i, "Title must be only: alphanumeric"
        end
      }.create :title => '$! title'
    }.message.should.match /Title must be only: alphanumeric/
  end

  it "allows varchar to be nil" do
    r = Class.new {
      include Datoki
      field(:title) {
        varchar nil
      }
    }.create()
    r.clean_data[:title].should == nil
  end

  it "sets field to return value of :set_to" do
    Class.new {
      include Datoki
      field(:title) {
        varchar
        set_to :custom_error
        def custom_error
          'Custom title'
        end
      }
    }.
    create(:title => 'My Title').
    clean_data[:title].should.match /Custom title/
  end

  it "strips varchars by default" do
    Class.new {
      include Datoki
      field(:title) { varchar }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == 'my title'
  end

  it "can prevent varchar from being stripped" do
    Class.new {
      include Datoki
      field(:title) {
        varchar
        disable :strip
      }
    }.
    create(:title => ' my title ').
    clean_data[:title].should == ' my title '
  end

  it "sets to nil if: string field, .strip.empty?, allow :null, no :min set" do
    r = Class.new {
      include Datoki
      record_errors
      field(:title) { varchar nil }
    }.create :title => '  '

    r.clean_data[:title].should == nil
  end

end # === describe Datoki ===

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

describe "on :create" do

  it "after all fields have been cleaned" do
    Class.new {

      include Datoki

      on :create, def collect_values
        clean_data[:values] = clean_data.values.join ', '
      end

      field(:title) { varchar }

      field(:body) { varchar }

    }.
    create(:title=>'my title', :body=>'my body').
    clean_data[:values].should == 'my title, my body'
  end

  it "runs after validation for a field" do
    Class.new {
      include Datoki
      field(:body) {
        on :create, def add_stuff
          clean_data[:body] << ' with new stuff'
        end

        varchar
      }
    }.
    create(:body=>'the body').
    clean_data[:body].should == 'the body with new stuff'
  end

end # === describe on :create

describe "on :update" do

  it "runs after data has been cleaned" do
    r = Class.new {
      include Datoki
      on :update, def do_something
        clean_data[:vals] = clean_data.values.join ' -- '
      end

      field(:title) { varchar }
      field(:body) { varchar }
    }.new(:title=>'old title')
    r.update title: ' new title ', :body=>'  new body  '
    r.clean_data[:vals].should == 'new title -- new body'
  end

end # === describe on :update

describe "Datoki.db" do

  before {

    CACHE[:datoki_db_test] ||= reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        title varchar(123) NOT NULL,
        body  text DEFAULT 'hello'
      );
    EOF

    @klass = Class.new {
      include Datoki
      record_errors
      table "datoki_test"
      field(:id) { integer; primary_key }
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 123 }
    }
  }

  it 'raises Schema_Conflict if a field is found that allows null, but not specifed to do so' do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:id) { integer; primary_key }
        field(:title) { varchar 1, 123 }
        field(:body) { text 1, 123 }
      }
    }.message.should.match /:allow_null: true != false/
  end

  it "requires field if value = null and default = null and :allow_null = false" do
    r = @klass.create :title=>nil, :body=>"hiya"
    r.errors.should == {:title=>{:msg=>'Title is required.', :value=>nil}}
  end

  it "requires a value if: :text field, value = (empty string), min = 1, allow null" do
    r = @klass.create :title=>"The title", :body=>'   '
    r.errors.should == {:body=>{:msg=>'Body is required.', :value=>""}}
  end

  it "does not turn strip.empty? strings into nulls" do
    r = @klass.create :title=>"The title", :body=>'   '
    r.clean_data[:body].should == ''
  end

  it "imports field names into class" do
    @klass.fields.keys.should == [:id, :title, :body]
  end

  it "imports field types into class" do
    @klass.fields.values.map { |meta| meta[:type] }.should == [:integer, :varchar, :text]
  end

  it "removes field from :clean_data if set to nil and database has a default value" do
    r = @klass.create :title=>'hello', :body=>nil
    r.clean_data.keys.should == [:title]
  end

end # === describe Datoki.db

describe "Datoki.db Schema_Conflict" do

  before {
    CACHE[:schema_conflict] ||= begin
                                  reset_db <<-EOF
                                    CREATE TABLE "datoki_test" (
                                      id     serial NOT NULL PRIMARY KEY,
                                      title  varchar(123),
                                      body   varchar(255) NOT NULL,
                                      created_at  timestamp with time zone NOT NULL DEFAULT timezone('UTC'::text, now())
                                    );
                                  EOF
                                end
  }

  it "raises Schema_Conflict when specified to allow nil, but db doesn not" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:body) { varchar nil, 1, 255 }
      }
    }.message.should.match /:allow_null: false != true/i
  end

  it "raises Schema_Conflict when there is a :max_length conflict" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:title) { varchar nil, 1, 200 }
      }
    }.message.should.match /:max: 123 != 200/i
  end

end # === describe Datoki.db

describe "Datoki.db :varchar" do

  before {
    CACHE[:datoki_db_varchar] ||= reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        title varchar(123) NOT NULL,
        body  text
      );
    EOF
    @klass = Class.new {
      include Datoki
      table "datoki_test"
      field(:id) { primary_key }
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 3000 }
    }
  }

  it "imports max length" do
    @klass.fields[:title][:max].should == 123
  end

  it "sets :min = 1 (by default, during import, if NOT NULL)" do
    @klass.fields[:title][:min].should == 1
  end

  it "sets :min = 1 (by default, during import, if :allow_null = true)" do
    @klass.fields[:body][:min].should == 1
  end

end # === describe Datoki.db :varchar

describe 'Datoki.db number' do

  before {
    CACHE[:datoki_db_number] ||= begin
                                    reset_db <<-EOF
                                      CREATE TABLE "datoki_test" (
                                        id serial NOT NULL PRIMARY KEY,
                                        parent_id smallint NOT NULL,
                                        title varchar(123) NOT NULL,
                                        body  text
                                      );
                                    EOF
                                  end
  }

  it "does not set :min = 1" do
    Class.new {
      include Datoki
      table "datoki_test"
      field(:parent_id) { smallint }
    }.
    fields[:parent_id][:min].should == nil
  end

end # === Datoki.db number

describe 'Datoki.db :new' do

  before {
    CACHE[:datoki_db_new] ||= begin
                                reset_db <<-EOF
                                      CREATE TABLE "datoki_test" (
                                        id serial NOT NULL PRIMARY KEY,
                                        parent_id smallint NOT NULL,
                                        title varchar(123) NOT NULL,
                                        body  text
                                      );
                                EOF
                              end
  }

  it "raises Schema_Conflict if field has not been defined, but exists in the db schema" do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:id) { primary_key }
        field(:parent_id) { smallint }
        field(:body) { text 1, 222 }
      }.new
    }.message.should.match /:title has not been defined/
  end

end # === describe Datoki.db :new




