
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
