


describe :html_escape do

  before {
    CACHE[:datoki_db_escape] ||= begin
                                   reset_db <<-EOF
                                    CREATE TABLE "datoki_test" (
                                      id serial NOT NULL PRIMARY KEY,
                                      parent_id smallint NOT NULL,
                                      title varchar(123) NOT NULL,
                                      url   varchar(255) NOT NULL,
                                      body  text         NOT NULL
                                    );
                                   EOF
                                 end

    @klass = Class.new {
      include Datoki
      table :datoki_test
      field(:id) { primary_key }
      field(:parent_id) { smallint }
      field(:title) { varchar 1, 123 }
      field(:url) { href }
      field(:body) { text 1, 244 }
    }
  }

  it "returns a hash of all defined fields" do
    @klass.html_escape.should == {
      :id        => :number,
      :parent_id => :number,
      :title     => :string,
      :url       => :href,
      :body      => :string
    }
  end

  it "sets :href for urls" do
    @klass.html_escape[:url].should == :href
  end

end # === describe :html_escape
