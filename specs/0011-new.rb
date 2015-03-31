
describe :new do

  before {
    CACHE[:datoki_db_test] ||= reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        title varchar(123) NOT NULL,
        body  text DEFAULT 'hello'
      );
    EOF

  } # === before

  it "saves hash as data" do
    klass = Class.new {
      include Datoki
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 123 }
    }
    r = klass.new(title: 'title1', body: 'body1')
    r.data[:title].should == 'title1'
  end # === it saves hash as data

  it "saves hash even for undefined, yet schema, fields" do
    klass = Class.new {
      include Datoki
      table :datoki_test
      field(:title) { varchar 1, 123 }
    }
    r = klass.new(id: 1, title: 'title1', body: 'body1')
    r.data[:title].should == 'title1'
  end # === it saves hash even for undefined, yet schema, fields

end # === describe :new


