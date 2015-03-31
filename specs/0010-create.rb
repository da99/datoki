
describe :create do

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
  } # === before

  it "throws :invalid for a violation of a unique key constraint of a defined field" do
    c = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { integer; primary_key; unique_index 'datoki_test_pkey' }
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 123 }

      def create
        clean :id, :title, :body
      end
    }
    r = @klass.create :title=>'the title', :body=>'yes yes yes'
    catch(:invalid) {
      c.create :id=>r.data[:id], :title=>r.data[:title], :body=>r.data[:body]
    }.error[:msg].should.match /Id already taken/
  end # === it


end # === describe :create
