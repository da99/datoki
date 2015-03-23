

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
