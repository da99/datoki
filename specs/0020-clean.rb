
describe :clean do

  it "adds field to @clean" do
    c = Class.new {
      include Datoki

      field(:nick_name) { varchar 1,50 }
      on(:happy?) { clean :nick_name }

      def happy?
        true
      end
    }

    c.new(:state=>:happy, :nick_name=>'Bob').
      clean[:nick_name].should == 'Bob'
  end # === it adds field to @clean

  it "skips cleaning if field is not defined" do
    c = Class.new {
      include Datoki

      field(:nick_name) { varchar 3, 255 }
      field(:age) { smallint }

      on :happy? do
        clean :nick_name, :age
      end

      def happy?
        true
      end
    }
    c.new(:nick_name=>'Wiley').
      clean.should == {:nick_name=>'Wiley'}
  end # === it skips cleaning if field is not defined

end # === describe :clean
