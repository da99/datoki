
describe :clean do

  it "adds field to @clean" do
    c = Class.new {
      include Datoki

      on :happy? do
        clean :nick_name, :string
      end

      def happy?
        @raw[:state] == :happy
      end
    }

    c.new(:state=>:happy, :nick_name=>'Bob').
      clean[:nick_name].should == 'Bob'
  end # === it adds field to @clean

  it "skips cleaning if field is not defined" do
    c = Class.new {
      include Datoki

      on :happy? do
        clean :nick_name, :string
        clean :age, :integer
      end

      def happy?
        true
      end
    }
    c.new(:nick_name=>'Wiley').
      clean.should == {:nick_name=>'Wiley'}
  end # === it skips cleaning if field is not defined

end # === describe :clean
