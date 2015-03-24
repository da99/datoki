
describe :clean do

  it "adds field to @clean" do
    c = Class.new {
      include Datoki

      field(:nick_name) { varchar 1,50 }
      def create
        clean :nick_name
        skip :db
      end

      def happy?
        true
      end
    }

    c.create(:state=>:happy, :nick_name=>'Bob').
      clean[:nick_name].should == 'Bob'
  end # === it adds field to @clean

  it "skips cleaning if field is not defined" do
    c = Class.new {
      include Datoki

      field(:nick_name) { varchar 3, 255 }
      field(:age) { smallint; allow :null }

      def create
        clean :nick_name, :age
        skip :db
      end
    }
    c.create(:nick_name=>'Wiley').
      clean.should == {:nick_name=>'Wiley'}
  end # === it skips cleaning if field is not defined

  it "fails w/ArgumentError if field is undefined, but required: :field!" do
    c = Class.new {
      include Datoki

      field(:name) { varchar }
      def create
        clean :name!
      end
    }

    should.raise(ArgumentError) {
      c.create(:nick=>'Bob')
    }.message.should.match /:name is not set/
  end # === it fails w/ArgumentError if underfined

end # === describe :clean
