
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

end # === describe :clean
