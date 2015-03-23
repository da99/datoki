
describe :on do

  it "executes proc if condition is true" do
    c = Class.new {
      include Datoki

      on :happy? do
        @result = :happy
      end

      on :sad? do
        @result= :happy
      end

      attr_reader :result

      def happy?
        @raw[:state] == :happy
      end

      def sad?
        @raw[:state] == :sad
      end
    }

    c.new(:state => :happy).
      result.should == :happy
  end # === it executes proc if condition is true

end # === describe :on
