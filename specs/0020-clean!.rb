
describe :clean! do

  it "fails w/ArgumentError if field is undefined" do
    c = Class.new {
      include Datoki

      field(:name) { varchar }
      def create
        clean! :name, :nick
      end
    }

    should.raise(ArgumentError) {
      c.create(:nick=>'Bob')
    }.message.should.match /:name is not set/
  end # === it fails w/ArgumentError if underfined

end # === describe :clean!
