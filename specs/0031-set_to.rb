
describe :set_to do

  it "sets val to block" do
    Class.new {
      include Datoki
      field(:age) {
        smallint
        set_to { |raw, val| val + 50 }
      }
      def create
        clean :age
      end
    }.create(:age=>20).
    clean.should == {:age=>70}
  end # === it sets val to lambda

  it "sets val to lambda" do
    Class.new {
      include Datoki
      field(:age) {
        smallint
        set_to(lambda { |raw, val| val + 10 })
      }
      def create
        clean :age
      end
    }.create(:age=>20).
    clean.should == {:age=>30}
  end # === it sets val to lambda

end # === describe :set_to
