
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

    c.create(:state => :happy).
      result.should == :happy
  end # === it executes proc if condition is true

  it "executes nested :on if condition matches" do
    c = Class.new {
      include Datoki

      RESULT = []

      attr_reader :result

      on :true? do
        on :filled? do
          @result ||= []
          @result << :found
        end
        on :false? do
          fail
        end
      end

      def false?
        false
      end

      def filled?
        true
      end

      def true?
        true
      end
    }
    c.create({}).result.should == [:found]
  end # === it executes nested :on if condition matches

end # === describe :on
