
describe :matching do

  before {
    CACHE[:datoki_matching] ||= begin
                                  reset_db <<-EOF
                                  CREATE TABLE "datoki_test" (
                                    id serial NOT NULL PRIMARY KEY,
                                    title varchar(15) NOT NULL,
                                    body  text NOT NULL,
                                    age   smallint NOT NULL
                                  );
                                  EOF
                                end
  }

  it "uses error message from :mis_match" do
    catch(:invalid) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:title) { varchar 5, 15, lambda { |r, val| false }; mis_match "Title is bad." }
        field(:body) { text 5, 10 }
        field(:age) { smallint }
        def create
          clean :title, :body, :age
        end
      }.create(:title=>'title', :body=>'body', :age=>50)
    }.error[:msg].should.match /Title is bad/
  end # === it uses error message from :mis_match

  it "inserts data into db if match w/Regexp matcher" do
    Class.new {
      include Datoki
      table :datoki_test
      field(:title) { varchar 5, 15, /title 4/ }
      field(:body) { text 5, 10 }
      field(:age) { smallint }
      def create
        clean :title, :body, :age
      end
    }.create(:title=>'title 4', :body=>'body 4', :age=>50)

    DB[:datoki_test].all.last.should == {:id=>1, :title=>'title 4', :body=>'body 4', :age=>50}
  end # === it inserts data into db if matcher returns true

  it "inserts data into db if lambda matcher returns true" do
    Class.new {
      include Datoki
      table :datoki_test
      field(:title) { varchar 5, 15, lambda { |r, val| true } }
      field(:body) { text 5, 10 }
      field(:age) { smallint }
      def create
        clean :title, :body, :age
      end
    }.create(:title=>'title 5', :body=>'body 5', :age=>50)

    DB[:datoki_test].all.last.should == {:id=>2, :title=>'title 5', :body=>'body 5', :age=>50}
  end # === it inserts data into db if matcher returns true

  it "throws :invalid if mis-match w/Regexp matcher" do
    should.throw(:invalid) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:title) { varchar 5, 15, /\Agood\Z/; mis_match "Title is really bad." }
        field(:body) { text 5, 10 }
        field(:age) { smallint }
        def create
          clean :title, :body, :age
        end
      }.create(:title=>'bad', :body=>'body', :age=>50)
    }.error[:msg].should.match /Title is really bad/
  end # === it accepts a Regexp as a matcher

  it "throws :invalid if lambda matcher returns false" do
    should.throw(:invalid) {
      Class.new {
        include Datoki
        table :datoki_test
        field(:title) { varchar 5, 15, lambda { |r, v| false } }
        field(:body) { text 5, 10 }
        field(:age) { smallint }
        def create
          clean :title, :body, :age
        end
      }.create(:title=>'title', :body=>'body', :age=>50)
    }.error[:msg].should.match /:title is invalid/
  end # === it throws :invalid if matcher returns false

end # === describe :matching
