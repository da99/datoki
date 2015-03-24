
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

  it "uses :big error msg" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field(:note) {
          string_ish 1,5
          big '{{English name}} can\'t be bigger than {{max}}.'
        }
        def create
          clean :note
        end
      }.create :note=>"1234567"
    }.error[:msg].should == "Note can\'t be bigger than 5."
  end # === it uses :big error msg

  it "uses :small error msg" do
    catch(:invalid) {
      Class.new {
        include Datoki
        field(:note) {
          string_ish 2,5
          small '{{English name}} can\'t be smaller than {{min}}.'
        }
        def create
          clean :note
        end
      }.create :note=>"1"
    }.error[:msg].should == "Note can\'t be smaller than 2."
  end # === it uses :small error msg

end # === describe :string
