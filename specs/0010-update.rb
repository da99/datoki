
describe :update do

  before {
    CACHE[:update] ||= reset_db <<-EOF
      CREATE TABLE "datoki_test" (
        id serial NOT NULL PRIMARY KEY,
        title varchar(123) NOT NULL,
        body  text DEFAULT 'hello'
      );
    EOF
  } # === before

  it "updates the record" do
    c = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { integer; primary_key }
      field(:title) { varchar 1, 123 }
      field(:body) { text nil, 1, 123 }

      def create
        clean :title, :body
      end

      def update
        clean :title, :body
      end
    }

    r = c.create :title=>'My Old', :body=>'My Old'
    c.update :id=>r.id, :title=>'My New Title', :body=>'My New Body'

    record = DB[:datoki_test].where(:id=>r.id).first
    record[:title].should == 'My New Title'
    record[:body].should  == 'My New Body'
  end # === it updates the record

end # === describe :update
