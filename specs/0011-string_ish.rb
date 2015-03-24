
describe :string do

  before {
    CACHE[:datoki_string] ||= begin
                                reset_db <<-EOF
                                  CREATE TABLE "datoki_test" (
                                    id serial NOT NULL PRIMARY KEY,
                                    ip inet   NOT NULL
                                  );
                                EOF
                              end
  }

  it "treats special PG types as a string" do
    Class.new {
      include Datoki
      table :datoki_test
      field(:ip) {
        string_ish 5, 50, /\A[0-9\:\.]+\Z/
        mis_match "Invalid format for ip: !val"
      }
      def create
        clean :ip
      end
    }.create(:ip=>'127.0.0.2')
    DB[:datoki_test].all.should == [{:id=>1, :ip=>'127.0.0.2'}]
  end # === it treats special PG types as a string

end # === describe :string
