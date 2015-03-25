
class Datoki_Test
end

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
      table :datoki_test
      field(:id) { integer; primary_key }
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 123 }

      def create
        clean :title, :body
      end
    }
  }

  it "sets :table_name to name of class" do
    class Datoki_Test
      include Datoki
      field(:title) { varchar 1,123  }
    end

    Datoki_Test.table_name.should == :datoki_test
  end # === it sets :table_name to name of class

  it "allows to save undefined field to the db" do
    Class.new {
      include Datoki
      table :datoki_test

      def create
        clean[:title] = 'title 123'
      end
    }.create({})
    DB[:datoki_test].all.last[:title].should == 'title 123'
  end # === it allows to save undefined field to the db

  it "allows an undefined field that exists in the db schema" do
    r = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { primary_key }
      field(:title) { varchar 1, 123 }
      def create
        clean :title
      end
    }.create(:title=>'title').data
    r[:title].should == 'title'
    r[:body].should == 'hello'
  end

  it 'raises Schema_Conflict if a field is found that allows null, but not specifed to do so' do
    should.raise(Datoki::Schema_Conflict) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:id) { integer; primary_key }
        field(:title) { varchar 1, 123 }
        field(:body) { text 1, 123 }
      }
    }.message.should.match /body: :allow_null: true != false/
  end

  it "requires field if value = null and :allow_null = false" do
    should.raise(Sequel::NotNullConstraintViolation) {
      @klass.create :title=>nil, :body=>"hiya"
    }.message.should.match /null value in column "title" violates not-null constraint/
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
