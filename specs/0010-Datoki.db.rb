

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

  it "requires field if value = null and :allow_null = false" do
    should.raise(ArgumentError) {
      @klass.create :title=>nil, :body=>"hiya"
    }.message.should.match /:title is not set/
  end

  it "requires a value if: :text field, value = (empty string), min = 1, allow null" do
    r = catch(:invalid) {
      @klass.create :title=>"The title", :body=>'   '
    }
    r.error.should == {:field_name=>:body, :msg=>'Body is required.', :value=>""}
  end

  it "does not turn strip.empty? strings into nulls" do
    r = catch(:invalid) { @klass.create :title=>"The title", :body=>'   ' }
    r.clean[:body].should == ''
  end

  it "imports field names into class" do
    @klass.fields.keys.should == [:id, :title, :body]
  end

  it "imports field types into class" do
    @klass.fields.values.map { |meta| meta[:type] }.should == [:integer, :varchar, :text]
  end

  it "removes field from :clean data if set to nil and database has a default value" do
    r = @klass.create :title=>'hello', :body=>nil
    r.clean.keys.should == [:title]
  end

end # === describe Datoki.db
