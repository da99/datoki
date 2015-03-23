
describe :clean! do

  it "fails w/ArgumentError if underfined" do
    c = Class.new {
      include Datoki

      on :happy? do
        clean! :name, :string
      end

      def happy?
        true
      end
    }
    should.raise(ArgumentError) {
      c.new(:happy=>true, :nick=>'Bob')
    }.message.should.match /name is not set/
  end # === it fails w/ArgumentError if underfined

end # === describe :clean!
