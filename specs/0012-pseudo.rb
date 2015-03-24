
describe :pseudo do

  before {
    CACHE[:datoki_pseudo] ||= begin
                                reset_db <<-EOF
                                  CREATE TABLE "datoki_test" (
                                    id serial NOT NULL PRIMARY KEY,
                                    title varchar(15) NOT NULL,
                                    body  text NOT NULL
                                  );
                                EOF
                              end
  }

  it "does not save values to database" do
    Class.new {
      include Datoki
      table :datoki_test
      field(:title) { varchar 5, 15 }
      field(:body) { text 5, 15 }
      field(:password) {
        string_ish 5, 10, /\A[a-z0-9\ ]+\Z/
        pseudo
      }
      def create
        clean :title, :body, :password
      end
    }.create(:title=>'Yo yo yo', :body=>'The body',:password=>'11111111')

    DB[:datoki_test].all.should == [{:id=>1,:title=>'Yo yo yo', :body=>'The body'}]
  end # === it does not save values to database

end # === describe :pseudo
